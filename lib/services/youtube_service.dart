import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart' as app;

class YouTubeService {
  YoutubeExplode? _yt;
  Map<String, String>? _cookies;

  YoutubeExplode get _client {
    _yt ??= YoutubeExplode();
    return _yt!;
  }

  void setCookies(Map<String, String> cookies) {
    _cookies = cookies;
  }

  void clearCookies() {
    _cookies = null;
  }

  Future<app.VideoInfo> fetchVideoInfo(String videoId) async {
    final video = await _client.videos.get(videoId);
    final thumbnailUrl = video.thumbnails.highResUrl;

    return app.VideoInfo(
      videoId: videoId,
      title: video.title,
      channelName: video.author,
      duration: video.duration ?? Duration.zero,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<StreamInfo> getBestAudioStream(String videoId) async {
    final manifest = await _client.videos.streamsClient.getManifest(videoId);
    final audioStreams = manifest.audioOnly.sortByBitrate();
    if (audioStreams.isEmpty) {
      throw Exception('No audio streams available');
    }
    return audioStreams.last; // Highest bitrate
  }

  Stream<List<int>> getAudioStream(StreamInfo streamInfo) {
    return _client.videos.streamsClient.get(streamInfo);
  }

  Future<File> downloadAudioStream({
    required String videoId,
    required String outputPath,
    required void Function(double progress, int downloaded, int total) onProgress,
  }) async {
    final streamInfo = await getBestAudioStream(videoId);
    final totalSize = streamInfo.size.totalBytes;
    final stream = getAudioStream(streamInfo);

    final file = File(outputPath);
    final sink = file.openWrite();
    var downloadedBytes = 0;

    await for (final chunk in stream) {
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
  }

  void dispose() {
    _yt?.close();
    _yt = null;
  }
}
