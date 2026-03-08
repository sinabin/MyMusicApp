import 'package:hive/hive.dart';

part 'dismissed_recommendation.g.dart';

/// 사용자가 dismiss한 추천 항목의 기록 모델.
///
/// Hive에 영속 저장되며, [DismissedRecommendationDb]를 통해 관리.
/// 90일 경과 시 자동 정리.
@HiveType(typeId: 1)
class DismissedRecommendation extends HiveObject {
  /// dismiss된 YouTube 영상 ID.
  @HiveField(0)
  final String videoId;

  /// dismiss 일시.
  @HiveField(1)
  final DateTime dismissedAt;

  DismissedRecommendation({
    required this.videoId,
    required this.dismissedAt,
  });
}
