import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart' as app;

/// YouTube 영상 메타데이터 조회 및 오디오 스트림 다운로드 서비스.
///
/// youtube_explode_dart를 사용하며, [DownloadService]에서 오디오 다운로드 시 참조.
class YouTubeService {
  YoutubeExplode? _yt;
  Map<String, String>? _cookies;

  /// 지연 초기화되는 [YoutubeExplode] 클라이언트 반환.
  YoutubeExplode get _client {
    _yt ??= YoutubeExplode();
    return _yt!;
  }

  /// 인증 쿠키 설정. 연령 제한 콘텐츠 접근 시 필요.
  void setCookies(Map<String, String> cookies) {
    _cookies = cookies;
  }

  /// 저장된 인증 쿠키 제거.
  void clearCookies() {
    _cookies = null;
  }

  /// [videoId]에 해당하는 영상 메타데이터를 조회하여 [VideoInfo] 반환.
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

  /// [videoId]의 가용 오디오 스트림 중 최고 비트레이트 스트림 반환.
  Future<StreamInfo> getBestAudioStream(String videoId) async {
    final manifest = await _client.videos.streamsClient.getManifest(videoId);
    final audioStreams = manifest.audioOnly.sortByBitrate();
    if (audioStreams.isEmpty) {
      throw Exception('No audio streams available');
    }
    return audioStreams.last; // Highest bitrate
  }

  /// [streamInfo]에 해당하는 오디오 바이트 스트림 반환.
  Stream<List<int>> getAudioStream(StreamInfo streamInfo) {
    return _client.videos.streamsClient.get(streamInfo);
  }

  /// 오디오 스트림을 [outputPath]에 파일로 다운로드. [onProgress]로 진행률 콜백 전달.
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

  /// [YoutubeExplode] 클라이언트 해제.
  void dispose() {
    _yt?.close();
    _yt = null;
  }
}
