import 'package:flutter/foundation.dart';
import '../models/video_info.dart';
import '../services/youtube_service.dart';

class VideoInfoProvider extends ChangeNotifier {
  final YouTubeService _youtubeService;

  VideoInfo? _videoInfo;
  bool _isLoading = false;
  String? _error;

  VideoInfoProvider({required YouTubeService youtubeService})
      : _youtubeService = youtubeService;

  VideoInfo? get videoInfo => _videoInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInfo(String videoId) async {
    _isLoading = true;
    _error = null;
    _videoInfo = null;
    notifyListeners();

    try {
      _videoInfo = await _youtubeService.fetchVideoInfo(videoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _videoInfo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _videoInfo = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
