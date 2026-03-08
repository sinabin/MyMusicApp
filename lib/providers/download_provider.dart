import 'package:flutter/foundation.dart';
import '../models/download_item.dart';
import '../models/download_state.dart';
import '../models/video_info.dart';
import '../services/audio_converter_service.dart';
import '../services/download_service.dart';
import '../services/file_service.dart';
import '../utils/format_utils.dart';

/// 다운로드 워크플로우(조회→다운로드→변환→완료) 상태를 관리하는 Provider.
///
/// [DownloadService]·[AudioConverterService]·[FileService]를 조합하여
/// 전체 과정을 제어하고, [DownloadStatus]를 통해 UI에 진행 상태를 전달.
class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService;
  final AudioConverterService _converterService;
  final FileService _fileService;

  DownloadStatus _status = const DownloadStatus();

  DownloadProvider({
    required DownloadService downloadService,
    required AudioConverterService converterService,
    required FileService fileService,
  })  : _downloadService = downloadService,
        _converterService = converterService,
        _fileService = fileService;

  /// 현재 다운로드 상태.
  DownloadStatus get status => _status;

  /// [videoInfo]의 오디오를 다운로드·변환하여 [DownloadItem] 반환. 취소·실패 시 null.
  Future<DownloadItem?> startDownload({
    required VideoInfo videoInfo,
    required String savePath,
    required int bitrate,
  }) async {
    try {
      // Phase 1: Fetching
      _status = const DownloadStatus(
        phase: DownloadPhase.fetching,
        statusText: 'Fetching audio stream...',
      );
      notifyListeners();

      // Phase 2: Downloading
      final tempPath = await _fileService.getTempPath();
      final tempFile = '$tempPath/${videoInfo.videoId}_temp';

      _status = _status.copyWith(
        phase: DownloadPhase.downloading,
        statusText: 'Downloading...',
      );
      notifyListeners();

      final downloadedFile = await _downloadService.downloadAudio(
        videoId: videoInfo.videoId,
        outputPath: tempFile,
        onProgress: (progress, downloaded, total) {
          _status = _status.copyWith(
            phase: DownloadPhase.downloading,
            progress: progress,
            downloadedBytes: downloaded,
            totalBytes: total,
            statusText:
                'Downloading... ${FormatUtils.fileSize(downloaded)} / ${FormatUtils.fileSize(total)}',
          );
          notifyListeners();
        },
      );

      if (downloadedFile == null) {
        // Cancelled
        _status = const DownloadStatus();
        notifyListeners();
        return null;
      }

      // Phase 3: Converting
      _status = _status.copyWith(
        phase: DownloadPhase.converting,
        progress: 0.0,
        statusText: 'Converting to MP3 (${bitrate}kbps)...',
      );
      notifyListeners();

      final outputPath = await _fileService.getUniqueFilePath(
        savePath,
        videoInfo.title,
        '.mp3',
      );

      final mp3File = await _converterService.convertToMp3(
        inputPath: tempFile,
        outputPath: outputPath,
        bitrate: bitrate,
      );

      if (mp3File == null) {
        throw Exception('Conversion failed');
      }

      // Phase 4: Completed
      final fileSize = await _fileService.getFileSize(outputPath);
      final fileName = outputPath.split('/').last;

      _status = DownloadStatus(
        phase: DownloadPhase.completed,
        progress: 1.0,
        statusText: 'Download Complete!',
      );
      notifyListeners();

      // Reset after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_status.phase == DownloadPhase.completed) {
          _status = const DownloadStatus();
          notifyListeners();
        }
      });

      return DownloadItem(
        fileName: fileName,
        filePath: outputPath,
        fileSize: fileSize,
        downloadDate: DateTime.now(),
        videoId: videoInfo.videoId,
        thumbnailUrl: videoInfo.thumbnailUrl,
      );
    } catch (e) {
      _status = DownloadStatus(
        phase: DownloadPhase.error,
        errorMessage: e.toString(),
        statusText: 'Failed - Tap to Retry',
      );
      notifyListeners();
      return null;
    }
  }

  /// 진행 중인 다운로드 취소.
  void cancel() {
    _downloadService.cancel();
  }

  /// 다운로드 상태 초기화.
  void reset() {
    _downloadService.reset();
    _status = const DownloadStatus();
    notifyListeners();
  }
}
