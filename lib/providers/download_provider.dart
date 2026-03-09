import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_exception.dart';
import '../models/download_item.dart';
import '../models/download_state.dart';
import '../models/video_info.dart';
import '../services/audio_converter_service.dart';
import '../services/download_service.dart';
import '../services/file_service.dart';
import '../utils/format_utils.dart';

/// 다운로드 워크플로우(조회→다운로드→저장→완료) 상태를 관리하는 Provider.
///
/// [DownloadService]·[AudioConverterService]·[FileService]를 조합하여
/// 전체 과정을 제어하고, [DownloadStatus]를 통해 UI에 진행 상태를 전달.
class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService;
  final AudioConverterService _converterService;
  final FileService _fileService;

  DownloadStatus _status = const DownloadStatus();
  String? _currentVideoId;
  Timer? _resetTimer;

  DownloadProvider({
    required DownloadService downloadService,
    required AudioConverterService converterService,
    required FileService fileService,
  })  : _downloadService = downloadService,
        _converterService = converterService,
        _fileService = fileService;

  /// 현재 다운로드 상태.
  DownloadStatus get status => _status;

  /// 현재 다운로드 중인 영상 ID. 대기 상태이면 null.
  String? get currentVideoId => _currentVideoId;

  /// [videoInfo]의 오디오를 다운로드하여 [DownloadItem] 반환. 취소·실패 시 null.
  Future<DownloadItem?> startDownload({
    required VideoInfo videoInfo,
    required String savePath,
  }) async {
    _resetTimer?.cancel();
    _currentVideoId = videoInfo.videoId;
    String? tempFile;

    try {
      // Phase 1: Fetching
      _status = const DownloadStatus(
        phase: DownloadPhase.fetching,
        statusText: 'Fetching audio stream...',
      );
      notifyListeners();

      // Phase 2: Downloading
      final tempPath = await _fileService.getTempPath();
      tempFile = '$tempPath/${videoInfo.videoId}_temp';

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
        _status = const DownloadStatus();
        notifyListeners();
        return null;
      }

      // Phase 3: Saving
      final outputPath = await _saveToOutput(videoInfo, tempFile, savePath);

      // Phase 3.5: 썸네일 로컬 저장 (실패해도 다운로드 결과에 영향 없음)
      final fileName = outputPath.split('/').last;
      await _fileService.saveThumbnail(videoInfo.thumbnailUrl, fileName);

      // Phase 4: Completed
      return await _buildResult(videoInfo, outputPath);
    } catch (e, st) {
      debugPrint('[DownloadProvider] Error (videoId=${videoInfo.videoId}): $e');
      debugPrint('[DownloadProvider] StackTrace: $st');
      await _cleanupTempFile(tempFile);
      final userMsg = e is AppException ? e.userMessage : 'Download failed';
      _status = DownloadStatus(
        phase: DownloadPhase.error,
        errorMessage: userMsg,
        statusText: 'Failed - Tap to Retry',
      );
      notifyListeners();
      return null;
    }
  }

  /// 임시 파일을 최종 저장 경로로 이동.
  Future<String> _saveToOutput(
    VideoInfo videoInfo,
    String tempFile,
    String savePath,
  ) async {
    _status = _status.copyWith(
      phase: DownloadPhase.converting,
      progress: 0.0,
      statusText: 'Saving audio file...',
    );
    notifyListeners();

    final effectiveSavePath = savePath.isNotEmpty
        ? savePath
        : await _fileService.getDefaultSavePath();

    final outputPath = await _fileService.getUniqueFilePath(
      effectiveSavePath,
      videoInfo.title,
      '.m4a',
    );

    final savedFile = await _converterService.moveToOutput(
      inputPath: tempFile,
      outputPath: outputPath,
    );

    if (savedFile == null) {
      throw Exception(
        'File save failed: videoId=${videoInfo.videoId}, path=$outputPath',
      );
    }

    return outputPath;
  }

  /// 다운로드 완료 상태 설정 및 [DownloadItem] 생성.
  Future<DownloadItem> _buildResult(
    VideoInfo videoInfo,
    String outputPath,
  ) async {
    final fileSize = await _fileService.getFileSize(outputPath);
    final fileName = outputPath.split('/').last;

    _status = const DownloadStatus(
      phase: DownloadPhase.completed,
      progress: 1.0,
      statusText: 'Download Complete!',
    );
    notifyListeners();
    _scheduleReset();

    return DownloadItem(
      fileName: fileName,
      filePath: outputPath,
      fileSize: fileSize,
      downloadDate: DateTime.now(),
      videoId: videoInfo.videoId,
      thumbnailUrl: videoInfo.thumbnailUrl,
      channelName: videoInfo.channelName,
      channelId: videoInfo.channelId,
      keywords: videoInfo.keywords,
      artistName: videoInfo.artistName,
    );
  }

  /// 완료 상태를 3초 후 초기화하는 타이머 등록.
  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (_status.phase == DownloadPhase.completed) {
        _status = const DownloadStatus();
        _currentVideoId = null;
        notifyListeners();
      }
    });
  }

  /// 임시 파일 정리. 실패 시 무시.
  Future<void> _cleanupTempFile(String? path) async {
    if (path == null) return;
    try {
      await _fileService.deleteFile(path);
    } catch (_) {}
  }

  /// 진행 중인 다운로드 취소.
  void cancel() {
    _resetTimer?.cancel();
    _downloadService.cancel();
  }

  /// 다운로드 상태 초기화.
  void reset() {
    _resetTimer?.cancel();
    _downloadService.reset();
    _status = const DownloadStatus();
    _currentVideoId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
