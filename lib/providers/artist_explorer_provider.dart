import 'package:flutter/foundation.dart';

import '../models/artist_node.dart';
import '../models/download_item.dart';
import '../models/recommendation.dart';
import '../services/artist_explorer_service.dart';

/// 아티스트 탐색 상태를 관리하는 Provider.
///
/// [ArtistExplorerService]를 통해 아티스트 목록, 인기곡, 관련 아티스트를 관리.
class ArtistExplorerProvider extends ChangeNotifier {
  final ArtistExplorerService _service;

  List<ArtistNode> _artists = [];
  List<Recommendation>? _selectedTracks;
  List<ArtistNode>? _relatedArtists;
  String? _selectedChannelId;
  bool _isLoading = false;
  bool _isLoadingTracks = false;
  bool _isLoadingRelated = false;

  ArtistExplorerProvider({required ArtistExplorerService service})
      : _service = service;

  /// 아티스트 목록.
  List<ArtistNode> get artists => _artists;

  /// 선택된 아티스트의 인기곡.
  List<Recommendation>? get selectedTracks => _selectedTracks;

  /// 관련 아티스트.
  List<ArtistNode>? get relatedArtists => _relatedArtists;

  /// 선택된 아티스트 채널 ID.
  String? get selectedChannelId => _selectedChannelId;

  /// 초기 로딩 상태.
  bool get isLoading => _isLoading;

  /// 인기곡 로딩 상태.
  bool get isLoadingTracks => _isLoadingTracks;

  /// 관련 아티스트 로딩 상태.
  bool get isLoadingRelated => _isLoadingRelated;

  /// 다운로드 이력에서 아티스트 목록 생성.
  void loadArtists(List<DownloadItem> history) {
    _isLoading = true;
    notifyListeners();

    _artists = _service.buildArtistList(history);

    _isLoading = false;
    notifyListeners();
  }

  /// 아티스트의 인기곡 로드.
  Future<void> loadArtistTracks(String channelId) async {
    if (_isLoadingTracks && _selectedChannelId == channelId) return;

    _selectedChannelId = channelId;
    _isLoadingTracks = true;
    _selectedTracks = null;
    notifyListeners();

    try {
      _selectedTracks = await _service.getArtistTopTracks(channelId);
    } catch (e) {
      debugPrint('[ArtistExplorerProvider] loadArtistTracks error: $e');
      _selectedTracks = [];
    } finally {
      _isLoadingTracks = false;
      notifyListeners();
    }
  }

  /// 관련 아티스트 로드.
  Future<void> loadRelatedArtists(String name) async {
    if (_isLoadingRelated) return;

    _isLoadingRelated = true;
    _relatedArtists = null;
    notifyListeners();

    try {
      _relatedArtists = await _service.getRelatedArtists(name);
    } catch (e) {
      debugPrint('[ArtistExplorerProvider] loadRelatedArtists error: $e');
      _relatedArtists = [];
    } finally {
      _isLoadingRelated = false;
      notifyListeners();
    }
  }

  /// 선택 상태 초기화.
  void clearSelection() {
    _selectedChannelId = null;
    _selectedTracks = null;
    _relatedArtists = null;
    notifyListeners();
  }
}
