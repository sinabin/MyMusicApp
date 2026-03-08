import 'package:flutter/foundation.dart';
import '../data/download_history_db.dart';
import '../data/playlist_db.dart';
import '../models/download_item.dart';
import '../models/playlist_item.dart';

/// 플레이리스트 상태를 관리하는 Provider.
///
/// [PlaylistDb]를 통해 플레이리스트를 CRUD하며,
/// [DownloadHistoryDb]를 참조하여 videoId → [DownloadItem] resolve 수행.
class PlaylistProvider extends ChangeNotifier {
  final PlaylistDb _db;
  final DownloadHistoryDb _downloadDb;
  List<PlaylistItem> _playlists = [];
  Future<void> _lock = Future.value();

  PlaylistProvider({
    required PlaylistDb db,
    required DownloadHistoryDb downloadDb,
  })  : _db = db,
        _downloadDb = downloadDb;

  /// 전체 플레이리스트 목록.
  List<PlaylistItem> get playlists => _playlists;

  /// 플레이리스트 개수.
  int get count => _playlists.length;

  /// DB에서 플레이리스트를 로드하여 갱신.
  void loadPlaylists() {
    _playlists = _db.getAll();
    notifyListeners();
  }

  /// 비동기 작업의 순차 실행을 보장하는 내부 동기화 래퍼.
  Future<void> _synchronized(Future<void> Function() fn) {
    return _lock = _lock.then((_) => fn());
  }

  /// 새 플레이리스트 생성 후 반환.
  Future<PlaylistItem> createPlaylist(
    String name, {
    String? description,
  }) async {
    final item = PlaylistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      description: description,
    );
    await _synchronized(() async {
      await _db.add(item);
      _playlists = _db.getAll();
      notifyListeners();
    });
    return item;
  }

  /// 플레이리스트 삭제.
  Future<void> deletePlaylist(PlaylistItem playlist) {
    return _synchronized(() async {
      await _db.remove(playlist);
      _playlists = _db.getAll();
      notifyListeners();
    });
  }

  /// 플레이리스트 이름 변경.
  Future<void> renamePlaylist(PlaylistItem playlist, String newName) {
    return _synchronized(() async {
      playlist.name = newName;
      await playlist.save();
      _playlists = _db.getAll();
      notifyListeners();
    });
  }

  /// 플레이리스트에 곡 추가.
  Future<void> addTrackToPlaylist(PlaylistItem playlist, String videoId) {
    return _synchronized(() async {
      if (!playlist.trackVideoIds.contains(videoId)) {
        playlist.trackVideoIds.add(videoId);
        await playlist.save();
        _playlists = _db.getAll();
        notifyListeners();
      }
    });
  }

  /// 플레이리스트에 여러 곡 일괄 추가.
  Future<void> addTracksToPlaylist(
    PlaylistItem playlist,
    List<String> videoIds,
  ) {
    return _synchronized(() async {
      final existing = playlist.trackVideoIds.toSet();
      final added = videoIds.where((id) => !existing.contains(id)).toList();
      if (added.isEmpty) return;
      playlist.trackVideoIds.addAll(added);
      await playlist.save();
      _playlists = _db.getAll();
      notifyListeners();
    });
  }

  /// 플레이리스트에서 곡 제거.
  Future<void> removeTrackFromPlaylist(PlaylistItem playlist, String videoId) {
    return _synchronized(() async {
      playlist.trackVideoIds.remove(videoId);
      await playlist.save();
      _playlists = _db.getAll();
      notifyListeners();
    });
  }

  /// 플레이리스트 내 곡 순서 변경.
  Future<void> reorderTracks(
    PlaylistItem playlist,
    int oldIndex,
    int newIndex,
  ) {
    return _synchronized(() async {
      if (newIndex > oldIndex) newIndex--;
      final ids = playlist.trackVideoIds;
      if (oldIndex < 0 || oldIndex >= ids.length) return;
      if (newIndex < 0 || newIndex >= ids.length) return;
      final id = ids.removeAt(oldIndex);
      ids.insert(newIndex, id);
      await playlist.save();
      _playlists = _db.getAll();
      notifyListeners();
    });
  }

  /// 플레이리스트의 곡 목록을 [DownloadItem]으로 resolve.
  ///
  /// DB에 존재하지 않는 고아 videoId는 자동 제거 후 저장.
  List<DownloadItem> getTracksForPlaylist(PlaylistItem playlist) {
    final allDownloads = _downloadDb.getAll();
    final downloadMap = <String, DownloadItem>{};
    for (final item in allDownloads) {
      downloadMap[item.videoId] = item;
    }
    final resolved = <DownloadItem>[];
    final validIds = <String>[];
    for (final id in playlist.trackVideoIds) {
      final item = downloadMap[id];
      if (item != null) {
        resolved.add(item);
        validIds.add(id);
      }
    }
    // 고아 videoId 정리.
    if (validIds.length != playlist.trackVideoIds.length) {
      playlist.trackVideoIds
        ..clear()
        ..addAll(validIds);
      playlist.save();
    }
    return resolved;
  }

  /// 플레이리스트에 아직 포함되지 않은 다운로드 곡 목록 반환.
  List<DownloadItem> getAvailableTracks(PlaylistItem playlist) {
    final existingIds = playlist.trackVideoIds.toSet();
    return _downloadDb
        .getAll()
        .where((item) => !existingIds.contains(item.videoId))
        .toList();
  }

  /// DB에 등록된 모든 다운로드 항목의 filePath 집합 반환.
  Set<String> get allTrackedPaths =>
      _downloadDb.getAll().map((e) => e.filePath).toSet();

  /// [item]을 다운로드 DB에 등록.
  ///
  /// 동일 filePath가 이미 존재하면 기존 항목의 videoId 반환.
  Future<String?> registerDownloadItem(DownloadItem item) async {
    final existing = await _downloadDb.add(item);
    return existing?.videoId;
  }
}
