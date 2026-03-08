import 'package:flutter/foundation.dart';
import '../models/video_info.dart';
import '../services/youtube_service.dart';

/// YouTube 영상 정보 조회 상태를 관리하는 Provider.
///
/// [YouTubeService]를 통해 메타데이터를 가져오며,
/// 로딩·에러·성공 상태를 [HomeScreen]에 제공.
class VideoInfoProvider extends ChangeNotifier {
  final YouTubeService _youtubeService;

  VideoInfo? _videoInfo;
  bool _isLoading = false;
  String? _error;

  /// 최신 요청의 videoId. 이전 요청 응답이 최신을 덮어쓰지 않도록 방어.
  String? _pendingVideoId;

  VideoInfoProvider({required YouTubeService youtubeService})
      : _youtubeService = youtubeService;

  /// 조회된 영상 정보. 미조회 시 null.
  VideoInfo? get videoInfo => _videoInfo;

  /// 영상 정보 조회 중 여부.
  bool get isLoading => _isLoading;

  /// 조회 실패 시 에러 메시지.
  String? get error => _error;

  /// [videoId]에 해당하는 영상 정보 비동기 조회.
  ///
  /// 연속 호출 시 마지막 요청만 결과에 반영.
  Future<void> fetchInfo(String videoId) async {
    _pendingVideoId = videoId;
    _isLoading = true;
    _error = null;
    _videoInfo = null;
    notifyListeners();

    try {
      final info = await _youtubeService.fetchVideoInfo(videoId);
      if (_pendingVideoId != videoId) return;
      _videoInfo = info;
      _error = null;
    } catch (e) {
      if (_pendingVideoId != videoId) return;
      _error = e.toString();
      _videoInfo = null;
    } finally {
      if (_pendingVideoId == videoId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 조회 상태 및 결과 초기화.
  void clear() {
    if (_videoInfo == null && _error == null && !_isLoading) return;
    _pendingVideoId = null;
    _videoInfo = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
