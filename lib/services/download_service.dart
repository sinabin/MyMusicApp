import 'dart:io';
import 'youtube_service.dart';

class DownloadService {
  final YouTubeService _youtubeService;
  bool _isCancelled = false;

  DownloadService(this._youtubeService);

  void cancel() {
    _isCancelled = true;
  }

  void reset() {
    _isCancelled = false;
  }

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
