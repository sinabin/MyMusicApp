import 'package:hive_flutter/hive_flutter.dart';
import '../models/dismissed_recommendation.dart';
import '../utils/constants.dart';

/// dismiss된 추천 항목의 영속 저장을 담당하는 데이터베이스 레이어.
///
/// [DownloadHistoryDb] 패턴을 재사용하며, [RecommendationProvider]가
/// 이 클래스를 통해 dismiss 기록을 관리.
class DismissedRecommendationDb {
  Box<DismissedRecommendation>? _box;

  /// Hive 초기화 및 [DismissedRecommendation] 전용 Box 오픈.
  Future<void> init() async {
    Hive.registerAdapter(DismissedRecommendationAdapter());
    _box = await Hive.openBox<DismissedRecommendation>(
      AppConstants.hiveDismissedBox,
    );
  }

  /// 초기화된 Hive [Box] 반환.
  Box<DismissedRecommendation> get box {
    if (_box == null) {
      throw StateError(
        'DismissedRecommendationDb not initialized. Call init() first.',
      );
    }
    return _box!;
  }

  /// dismiss 기록 추가.
  Future<void> add(String videoId) async {
    await box.add(DismissedRecommendation(
      videoId: videoId,
      dismissedAt: DateTime.now(),
    ));
  }

  /// dismiss된 모든 videoId 반환.
  Set<String> getAllVideoIds() {
    return box.values.map((e) => e.videoId).toSet();
  }

  /// 90일 이상 지난 dismiss 기록 정리.
  Future<void> cleanup() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final stale =
        box.values.where((e) => e.dismissedAt.isBefore(cutoff)).toList();
    for (final item in stale) {
      await item.delete();
    }
  }
}
