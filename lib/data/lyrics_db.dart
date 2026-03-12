import 'package:hive_flutter/hive_flutter.dart';

import '../models/lyrics_cache.dart';
import '../utils/constants.dart';

/// [LyricsCache]의 영속 저장을 담당하는 데이터베이스 레이어.
///
/// Hive Box를 통해 가사 캐시를 관리. [LyricsService]에서 캐시 조회 및 저장 시 사용.
class LyricsDb {
  Box<LyricsCache>? _box;

  /// Hive 어댑터 등록 및 Box 오픈.
  Future<void> init() async {
    Hive.registerAdapter(LyricsCacheAdapter());
    _box = await Hive.openBox<LyricsCache>(AppConstants.hiveLyricsBox);
  }

  /// 초기화 완료 여부.
  bool get isInitialized => _box != null;

  /// 초기화된 Hive [Box] 반환.
  Box<LyricsCache> get box {
    if (_box == null) {
      throw StateError('LyricsDb not initialized. Call init() first.');
    }
    return _box!;
  }

  /// [videoId]로 캐시된 가사 조회.
  LyricsCache? getByVideoId(String videoId) {
    try {
      return box.values.firstWhere((e) => e.videoId == videoId);
    } catch (_) {
      return null;
    }
  }

  /// 가사 캐시 저장.
  Future<void> save(LyricsCache cache) async {
    await box.add(cache);
  }

  /// [videoId]에 해당하는 캐시 삭제.
  Future<void> deleteByVideoId(String videoId) async {
    final entries = box.values.where((e) => e.videoId == videoId).toList();
    for (final entry in entries) {
      await entry.delete();
    }
  }

  /// [maxAgeDays]일 이전의 오래된 캐시 삭제.
  Future<void> cleanup({int maxAgeDays = 180}) async {
    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
    final stale = box.values.where((e) => e.cachedAt.isBefore(cutoff)).toList();
    for (final item in stale) {
      await item.delete();
    }
  }
}
