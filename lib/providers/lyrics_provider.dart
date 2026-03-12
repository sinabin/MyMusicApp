import 'package:flutter/foundation.dart';

import '../models/download_item.dart';
import '../services/lyrics_service.dart';

/// 가사 상태를 관리하는 Provider.
///
/// 곡 변경 시 [loadLyrics]를 호출하여 가사를 자동 갱신.
/// [LyricsService]에 조회를 위임.
class LyricsProvider extends ChangeNotifier {
  final LyricsService _service;

  String? _lyrics;
  bool _isLoading = false;
  bool _notFound = false;
  String? _currentVideoId;

  LyricsProvider({required LyricsService service}) : _service = service;

  /// 현재 가사 텍스트.
  String? get lyrics => _lyrics;

  /// 로딩 상태.
  bool get isLoading => _isLoading;

  /// 가사 미발견 상태.
  bool get notFound => _notFound;

  /// 곡의 가사 로드.
  Future<void> loadLyrics(DownloadItem track) async {
    // 동일 곡 중복 로딩 방지
    if (_currentVideoId == track.videoId && !_notFound && _lyrics != null) {
      return;
    }

    _currentVideoId = track.videoId;
    _isLoading = true;
    _notFound = false;
    _lyrics = null;
    notifyListeners();

    try {
      final title = track.fileName.endsWith('.m4a')
          ? track.fileName.substring(0, track.fileName.length - 4)
          : track.fileName;

      final result = await _service.getLyrics(
        videoId: track.videoId,
        trackName: title,
        artistName: track.artistName,
      );

      // 비동기 응답이 돌아온 시점에 곡이 바뀌었으면 무시
      if (_currentVideoId != track.videoId) return;

      _lyrics = result;
      _notFound = result == null;
    } catch (e) {
      debugPrint('[LyricsProvider] Load error: $e');
      _notFound = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 캐시를 무시하고 가사 재검색.
  Future<void> retryLyrics(DownloadItem track) async {
    _currentVideoId = track.videoId;
    _isLoading = true;
    _notFound = false;
    _lyrics = null;
    notifyListeners();

    try {
      final title = track.fileName.endsWith('.m4a')
          ? track.fileName.substring(0, track.fileName.length - 4)
          : track.fileName;

      final result = await _service.getLyrics(
        videoId: track.videoId,
        trackName: title,
        artistName: track.artistName,
        forceRefresh: true,
      );

      if (_currentVideoId != track.videoId) return;

      _lyrics = result;
      _notFound = result == null;
    } catch (e) {
      debugPrint('[LyricsProvider] Retry error: $e');
      _notFound = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 가사 상태 초기화.
  void clear() {
    _currentVideoId = null;
    _lyrics = null;
    _isLoading = false;
    _notFound = false;
    notifyListeners();
  }
}
