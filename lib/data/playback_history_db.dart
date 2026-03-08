import 'package:hive_flutter/hive_flutter.dart';
import '../models/playback_record.dart';
import '../utils/constants.dart';

/// [PlaybackRecord]의 영속 저장을 담당하는 데이터베이스 레이어.
///
/// [DismissedRecommendationDb] 패턴을 재사용하며, [PlaybackHistoryProvider]가
/// 이 클래스를 통해 재생 기록을 관리.
class PlaybackHistoryDb {
  Box<PlaybackRecord>? _box;

  /// Hive 어댑터 등록 및 Box 오픈.
  Future<void> init() async {
    Hive.registerAdapter(PlaybackRecordAdapter());
    _box = await Hive.openBox<PlaybackRecord>(AppConstants.hivePlaybackBox);
  }

  /// 초기화된 Hive [Box] 반환.
  Box<PlaybackRecord> get box {
    if (_box == null) {
      throw StateError(
        'PlaybackHistoryDb not initialized. Call init() first.',
      );
    }
    return _box!;
  }

  /// 재생 기록 추가.
  Future<void> add(PlaybackRecord record) async {
    await box.add(record);
  }

  /// 전체 재생 기록을 재생일 내림차순으로 반환.
  List<PlaybackRecord> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  /// 최근 재생된 고유 videoId 목록 반환 (중복 제거, 순서 유지).
  List<String> getRecentVideoIds(int limit) {
    final all = getAll();
    final seen = <String>{};
    final result = <String>[];
    for (final record in all) {
      if (seen.add(record.videoId)) {
        result.add(record.videoId);
        if (result.length >= limit) break;
      }
    }
    return result;
  }

  /// [maxAgeDays]일 이전의 오래된 기록 삭제.
  Future<void> cleanup({int maxAgeDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
    final stale =
        box.values.where((e) => e.playedAt.isBefore(cutoff)).toList();
    for (final item in stale) {
      await item.delete();
    }
  }

  /// 모든 재생 기록 삭제.
  Future<void> clear() async {
    await box.clear();
  }
}
