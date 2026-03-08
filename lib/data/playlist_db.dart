import 'package:hive_flutter/hive_flutter.dart';
import '../models/playlist_item.dart';
import '../utils/constants.dart';

/// [PlaylistItem]의 영속 저장을 담당하는 데이터베이스 레이어.
///
/// [DismissedRecommendationDb] 패턴을 재사용하며, [PlaylistProvider]가
/// 이 클래스를 통해 플레이리스트를 관리.
class PlaylistDb {
  Box<PlaylistItem>? _box;

  /// Hive 어댑터 등록 및 Box 오픈.
  Future<void> init() async {
    Hive.registerAdapter(PlaylistItemAdapter());
    _box = await Hive.openBox<PlaylistItem>(AppConstants.hivePlaylistBox);
  }

  /// 초기화된 Hive [Box] 반환.
  Box<PlaylistItem> get box {
    if (_box == null) {
      throw StateError('PlaylistDb not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 전체 플레이리스트를 생성일 내림차순으로 반환.
  List<PlaylistItem> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 플레이리스트 추가.
  Future<void> add(PlaylistItem item) async {
    await box.add(item);
  }

  /// [id]에 해당하는 플레이리스트 반환.
  PlaylistItem? getById(String id) {
    try {
      return box.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 플레이리스트 삭제.
  Future<void> remove(PlaylistItem item) async {
    await item.delete();
  }
}
