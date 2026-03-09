import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/app_exception.dart';
import '../models/video_info.dart' as app;
import 'auth_service.dart';

/// YouTube 영상 메타데이터 조회 및 오디오 스트림 다운로드 서비스.
///
/// [AuthService]의 쿠키를 [YoutubeHttpClient]에 주입하여
/// 연령 제한 콘텐츠 접근을 지원. [DownloadService]에서 오디오 다운로드 시 참조.
class YouTubeService {
  final AuthService _authService;
  YoutubeExplode? _yt;

  YouTubeService({required AuthService authService})
      : _authService = authService;

  /// 인증 쿠키가 포함된 [YoutubeExplode] 클라이언트 반환.
  Future<YoutubeExplode> get _client async {
    if (_yt == null) {
      await _initClient();
    }
    return _yt!;
  }

  /// [AuthService]에서 쿠키를 로드하여 클라이언트 초기화.
  Future<void> _initClient() async {
    final cookies = await _authService.loadCookies();
    if (cookies != null && cookies.isNotEmpty) {
      final cookieStr = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      final httpClient = _AuthedYoutubeHttpClient(cookieStr);
      _yt = YoutubeExplode(httpClient: httpClient);
      debugPrint('[YouTubeService] Initialized with auth cookies');
    } else {
      _yt = YoutubeExplode();
      debugPrint('[YouTubeService] Initialized without auth');
    }
  }

  /// 로그인/로그아웃 후 클라이언트를 재생성하여 인증 상태 반영.
  Future<void> refreshClient() async {
    _yt?.close();
    _yt = null;
    await _initClient();
  }

  /// [videoId]에 해당하는 영상 메타데이터를 조회하여 [VideoInfo] 반환.
  Future<app.VideoInfo> fetchVideoInfo(String videoId) async {
    final client = await _client;
    final video = await client.videos.get(videoId);
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
    final client = await _client;
    return await client.videos.get(videoId);
  }

  /// [video]의 관련 영상 목록 반환.
  Future<RelatedVideosList?> getRelatedVideos(Video video) async {
    final client = await _client;
    return await client.videos.getRelatedVideos(video);
  }

  /// [channelId]의 업로드 영상 목록 반환 (페이지네이션).
  Future<ChannelUploadsList> getChannelUploads(
    String channelId, {
    VideoSorting videoSorting = VideoSorting.newest,
  }) async {
    final client = await _client;
    return await client.channels.getUploadsFromPage(
      channelId,
      videoSorting: videoSorting,
    );
  }

  /// [query]로 YouTube 검색 수행.
  Future<VideoSearchList> searchVideos(String query) async {
    try {
      final client = await _client;
      return await client.search.search(query);
    } catch (e) {
      if (e is AppException) rethrow;
      throw SearchException(
        message: 'Search failed for query="$query": $e',
        cause: e,
      );
    }
  }

  /// [videoId]의 가용 오디오 스트림 중 최고 비트레이트 스트림 반환.
  Future<StreamInfo> getBestAudioStream(String videoId) async {
    try {
      final client = await _client;
      final manifest = await client.videos.streams.getManifest(
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
        throw StreamNotFoundException(videoId: videoId);
      }
      return audioStreams.first; // Highest bitrate (sortByBitrate는 내림차순)
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Failed to get audio stream for videoId=$videoId: $e',
        cause: e,
      );
    }
  }

  /// [videoId]의 최고 비트레이트 오디오 스트림 URL 반환.
  Future<Uri> getAudioStreamUrl(String videoId) async {
    final streamInfo = await getBestAudioStream(videoId);
    return streamInfo.url;
  }

  /// [streamInfo]에 해당하는 오디오 바이트 스트림 반환.
  Future<Stream<List<int>>> getAudioStream(StreamInfo streamInfo) async {
    final client = await _client;
    return client.videos.streams.get(streamInfo);
  }

  /// [YoutubeExplode] 클라이언트 해제.
  void dispose() {
    _yt?.close();
    _yt = null;
  }
}

/// 인증 쿠키를 요청 헤더에 주입하는 [YoutubeHttpClient] 확장.
class _AuthedYoutubeHttpClient extends YoutubeHttpClient {
  final String _cookie;

  _AuthedYoutubeHttpClient(this._cookie);

  @override
  Map<String, String> get headers => {
        ...YoutubeHttpClient.defaultHeaders,
        'cookie': _cookie,
      };
}
