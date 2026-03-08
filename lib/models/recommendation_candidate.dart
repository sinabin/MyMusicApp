import 'recommendation.dart';

/// 추천 파이프라인 내부에서 사용되는 후보 모델.
///
/// 점수 산정·중복 카운트 등 순위 결정 데이터를 포함하며,
/// [CandidateRanker]에서 [Recommendation]으로 변환.
class RecommendationCandidate {
  /// YouTube 영상 ID.
  final String videoId;

  /// 영상 제목.
  final String title;

  /// 채널(업로더) 이름.
  final String channelName;

  /// 채널 ID.
  final String channelId;

  /// 영상 재생 시간.
  final Duration? duration;

  /// 썸네일 이미지 URL.
  final String thumbnailUrl;

  /// 추천 소스 유형.
  final RecommendationSource source;

  /// 관련 영상 전략에서의 시드 영상 ID.
  final String? sourceVideoId;

  /// 채널 전략에서의 시드 채널 ID.
  final String? sourceChannelId;

  /// 검색 전략에서의 검색 쿼리.
  final String? sourceQuery;

  /// 복수 전략에서 등장한 횟수.
  int duplicateCount = 1;

  /// 최종 산출 점수.
  double score = 0;

  RecommendationCandidate({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.channelId,
    this.duration,
    required this.thumbnailUrl,
    required this.source,
    this.sourceVideoId,
    this.sourceChannelId,
    this.sourceQuery,
  });

  /// [Recommendation]으로 변환.
  Recommendation toRecommendation(String reason) {
    return Recommendation(
      videoId: videoId,
      title: title,
      channelName: channelName,
      channelId: channelId,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      source: source,
      reason: reason,
    );
  }
}
