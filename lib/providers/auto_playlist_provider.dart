import 'package:flutter/foundation.dart';
import '../models/auto_playlist.dart';
import '../models/download_item.dart';
import '../services/classification/auto_playlist_service.dart';

/// 자동 플레이리스트 상태를 관리하는 Provider.
///
/// [AutoPlaylistService]를 통해 다운로드 목록에서 스마트 믹스를 생성하고
/// UI에 노출.
class AutoPlaylistProvider extends ChangeNotifier {
  final AutoPlaylistService _service;

  List<AutoPlaylist> _playlists = [];
  bool _isLoading = false;
  String? _error;

  AutoPlaylistProvider({required AutoPlaylistService service})
      : _service = service;

  /// 자동 플레이리스트 목록.
  List<AutoPlaylist> get playlists => _playlists;

  /// 로딩 상태.
  bool get isLoading => _isLoading;

  /// 에러 메시지.
  String? get error => _error;

  /// 다운로드 목록에서 자동 플레이리스트 생성.
  Future<void> generate(List<DownloadItem> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playlists = _service.generatePlaylists(items);
    } catch (e) {
      debugPrint('[AutoPlaylistProvider] Generate error: $e');
      _error = '스마트 믹스 생성에 실패했습니다';
      _playlists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
