import 'dart:io';
import 'youtube_service.dart';

/// 오디오 스트림 다운로드를 수행하며 취소 기능을 제공하는 서비스.
///
/// [YouTubeService]를 주입받아 스트림을 가져오고, [DownloadProvider]에서 사용.
class DownloadService {
  final YouTubeService _youtubeService;
  bool _isCancelled = false;

  DownloadService(this._youtubeService);

  /// 진행 중인 다운로드 취소 요청.
  void cancel() {
    _isCancelled = true;
  }

  /// 취소 플래그 초기화.
  void reset() {
    _isCancelled = false;
  }

  /// [videoId]의 오디오를 [outputPath]에 다운로드. 취소 시 임시 파일 삭제 후 null 반환.
  Future<File?> downloadAudio({
    required String videoId,
    required String outputPath,
    required void Function(double progress, int downloaded, int total) onProgress,
  }) async {
    _isCancelled = false;

    try {
      final streamInfo = await _youtubeService.getBestAudioStream(videoId);
      final totalSize = streamInfo.size.totalBytes;
      final stream = _youtubeService.getAudioStream(streamInfo);

      final file = File(outputPath);
      final sink = file.openWrite();
      var downloadedBytes = 0;

      await for (final chunk in stream) {
        if (_isCancelled) {
          await sink.close();
          if (await file.exists()) {
            await file.delete();
          }
          return null;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;
        onProgress(
          downloadedBytes / totalSize,
          downloadedBytes,
          totalSize,
        );
      }

      await sink.flush();
      await sink.close();
      return file;
    } catch (e) {
      rethrow;
    }
  }
}
