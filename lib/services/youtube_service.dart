import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart' as app;

/// YouTube 영상 메타데이터 조회 및 오디오 스트림 다운로드 서비스.
///
/// youtube_explode_dart를 사용하며, [DownloadService]에서 오디오 다운로드 시 참조.
class YouTubeService {
  YoutubeExplode? _yt;

  /// 지연 초기화되는 [YoutubeExplode] 클라이언트 반환.
  YoutubeExplode get _client {
    _yt ??= YoutubeExplode();
    return _yt!;
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
      channelId: video.channelId.value,
      keywords: video.keywords.toList(),
      artistName:
          video.musicData.isNotEmpty ? video.musicData.first.artist : null,
    );
  }

  /// [videoId]의 전체 메타데이터 반환 (keywords, musicData 포함).
  Future<Video> getVideo(String videoId) async {
    return await _client.videos.get(videoId);
  }

  /// [video]의 관련 영상 목록 반환.
  Future<RelatedVideosList?> getRelatedVideos(Video video) async {
    return await _client.videos.getRelatedVideos(video);
  }

  /// [channelId]의 업로드 영상 목록 반환 (페이지네이션).
  Future<ChannelUploadsList> getChannelUploads(
    String channelId, {
    VideoSorting videoSorting = VideoSorting.newest,
  }) async {
    return await _client.channels.getUploadsFromPage(
      channelId,
      videoSorting: videoSorting,
    );
  }

  /// [query]로 YouTube 검색 수행.
  Future<VideoSearchList> searchVideos(String query) async {
    return await _client.search.search(query);
  }

  /// [videoId]의 가용 오디오 스트림 중 최고 비트레이트 스트림 반환.
  Future<StreamInfo> getBestAudioStream(String videoId) async {
    final manifest = await _client.videos.streams.getManifest(
      videoId,
      ytClients: [
        YoutubeApiClient.safari,
        YoutubeApiClient.androidVr,
      ],
    );

    final audioStreams = manifest.audioOnly.sortByBitrate();
    debugPrint('[YouTubeService] Available audio streams: ${audioStreams.length}');
    for (final s in audioStreams) {
      debugPrint('[YouTubeService]   - ${s.codec} ${s.bitrate} ${s.size}');
    }

    if (audioStreams.isEmpty) {
      throw Exception('No audio streams available for videoId=$videoId');
    }
    return audioStreams.first; // Highest bitrate (sortByBitrate는 내림차순)
  }

  /// [streamInfo]에 해당하는 오디오 바이트 스트림 반환.
  Stream<List<int>> getAudioStream(StreamInfo streamInfo) {
    return _client.videos.streams.get(streamInfo);
  }

  /// [YoutubeExplode] 클라이언트 해제.
  void dispose() {
    _yt?.close();
    _yt = null;
  }
}
