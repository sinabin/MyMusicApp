import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart';
import '../services/youtube_service.dart';

/// YouTube 검색 상태를 관리하는 Provider.
///
/// [YouTubeService]를 통해 검색을 수행하고 결과·로딩·에러 상태를
/// [SearchScreen]에 제공. 페이지네이션 지원.
class SearchProvider extends ChangeNotifier {
  final YouTubeService _youtubeService;

  VideoSearchList? _searchList;
  List<VideoInfo> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _query = '';

  /// 동시성 방어용 검색 세션 카운터. [search] 호출마다 증가.
  int _searchSession = 0;

  SearchProvider({required YouTubeService youtubeService})
      : _youtubeService = youtubeService;

  /// 검색 결과 목록.
  List<VideoInfo> get results => _results;

  /// 검색 진행 중 여부.
  bool get isLoading => _isLoading;

  /// 추가 결과 로딩 중 여부.
  bool get isLoadingMore => _isLoadingMore;

  /// 검색 실패 시 에러 메시지.
  String? get error => _error;

  /// 현재 검색어.
  String get query => _query;

  /// 추가 결과 존재 여부.
  bool get hasMore => _searchList != null;

  /// [query]로 YouTube 검색 수행. 연속 호출 시 마지막 요청만 반영.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final session = ++_searchSession;
    _query = trimmed;
    _isLoading = true;
    _error = null;
    _results = [];
    _searchList = null;
    notifyListeners();

    try {
      final searchList = await _youtubeService.searchVideos(_query);
      if (session != _searchSession) return;
      _searchList = searchList;
      _results = searchList.map<VideoInfo>(_toVideoInfo).toList();
    } catch (e) {
      if (session != _searchSession) return;
      _error = e.toString();
    } finally {
      if (session == _searchSession) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 다음 페이지 검색 결과 로드.
  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || _searchList == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = await _searchList!.nextPage();
      if (nextPage != null && nextPage.isNotEmpty) {
        _searchList = nextPage;
        _results = [..._results, ...nextPage.map<VideoInfo>(_toVideoInfo)];
      } else {
        _searchList = null;
      }
    } catch (e) {
      debugPrint('[SearchProvider] loadMore error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 검색 상태 초기화.
  void clear() {
    if (_results.isEmpty && !_isLoading && _error == null) return;
    _searchSession++;
    _results = [];
    _searchList = null;
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    _query = '';
    notifyListeners();
  }

  /// [Video]를 [VideoInfo]로 변환.
  VideoInfo _toVideoInfo(Video video) {
    return VideoInfo(
      videoId: video.id.value,
      title: video.title,
      channelName: video.author,
      duration: video.duration ?? Duration.zero,
      thumbnailUrl: 'https://img.youtube.com/vi/${video.id.value}/hqdefault.jpg',
    );
  }
}
