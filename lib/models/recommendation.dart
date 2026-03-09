/// 추천 결과의 소스 유형.
enum RecommendationSource { related, channel, search, trending }

/// UI에 표시되는 추천 결과 모델.
///
/// [RecommendationCandidate]에서 점수 산정·필터링 후 변환되며,
/// [RecommendationCard]에서 렌더링.
class Recommendation {
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

  /// 추천 사유 (UI 표시용).
  final String reason;

  const Recommendation({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.channelId,
    this.duration,
    required this.thumbnailUrl,
    required this.source,
    required this.reason,
  });
}
