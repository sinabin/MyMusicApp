import 'recommendation.dart';

/// 섹션별로 분류된 추천 결과 모델.
///
/// [RecommendationProvider]에서 캐싱하며, [DiscoverScreen]에서 섹션별 렌더링.
class SectionedRecommendations {
  /// 기존 파이프라인 기반 맞춤 추천.
  final List<Recommendation> forYou;

  /// 트렌딩 음악 추천.
  final List<Recommendation> trending;

  /// 관련 영상 기반 유사곡 추천.
  final List<Recommendation> similarSongs;

  const SectionedRecommendations({
    required this.forYou,
    required this.trending,
    required this.similarSongs,
  });

  /// 모든 섹션의 추천 항목 통합 리스트 반환.
  List<Recommendation> get all => [...forYou, ...trending, ...similarSongs];

  /// 모든 섹션이 비어있는지 확인.
  bool get isEmpty => forYou.isEmpty && trending.isEmpty && similarSongs.isEmpty;
}
