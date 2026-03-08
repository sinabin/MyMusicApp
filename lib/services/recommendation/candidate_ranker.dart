import '../../models/recommendation.dart';
import '../../models/recommendation_candidate.dart';

/// 추천 후보를 필터링·점수 산정·정렬하여 최종 추천 목록을 생성하는 랭커.
///
/// [CandidateFetcher]가 수집한 후보를 받아 파이프라인을 적용:
/// 중복 카운트 → 중복 제거 → 필터링 → 점수 산정 → 정렬 → 상위 20건.
class CandidateRanker {
  // ─── 점수 가중치 상수 ──────────────────────────────────────

  /// 소스별 기본 점수: related(가장 관련성 높음) > channel > search.
  static const _scoreRelated = 3.0;
  static const _scoreChannel = 2.0;
  static const _scoreSearch = 1.0;

  /// 일반적 음악 길이(1~7분)에 부여하는 가산점.
  static const _scoreDurationIdeal = 2.0;

  /// 중간 길이(7~15분)에 부여하는 가산점.
  static const _scoreDurationMedium = 0.5;

  /// 복수 전략 중복 시 건당 가산점.
  static const _scoreDuplicateBonus = 2.5;

  // ─── 필터링 임계값 ─────────────────────────────────────────

  /// 최소 재생 시간(초). 이하는 비음악으로 판정.
  static const _minDurationSec = 30;

  /// 최대 재생 시간(분). 이상은 비음악으로 판정.
  static const _maxDurationMin = 20;

  /// 비음악 콘텐츠를 식별하는 키워드 패턴.
  static final _nonMusicPattern = RegExp(
    r'interview|reaction|podcast|review|unboxing|vlog|'
    r'tutorial|lecture|강의|리액션|리뷰|팟캐스트',
    caseSensitive: false,
  );

  /// 최종 추천 목록 최대 건수.
  static const _maxResults = 20;

  // ─── 인스턴스 필드 ─────────────────────────────────────────

  final Set<String> _downloadedVideoIds;
  final Set<String> _dismissedVideoIds;

  /// 다운로드 이력의 제목 맵 (관련 영상 사유 생성용).
  final Map<String, String> _downloadedTitleMap;

  CandidateRanker({
    required Set<String> downloadedVideoIds,
    required Set<String> dismissedVideoIds,
    required Map<String, String> downloadedTitleMap,
  })  : _downloadedVideoIds = downloadedVideoIds,
        _dismissedVideoIds = dismissedVideoIds,
        _downloadedTitleMap = downloadedTitleMap;

  /// 후보 목록을 필터링·점수 산정·정렬하여 최종 추천 목록 반환.
  List<Recommendation> rank(List<RecommendationCandidate> candidates) {
    _countDuplicates(candidates);
    _dedup(candidates);
    _filterOut(candidates);
    _score(candidates);
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(_maxResults).map(_toRecommendation).toList();
  }

  /// 동일 videoId가 복수 전략에서 등장한 횟수 기록.
  void _countDuplicates(List<RecommendationCandidate> candidates) {
    final countMap = <String, int>{};
    for (final c in candidates) {
      countMap.update(c.videoId, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final c in candidates) {
      c.duplicateCount = countMap[c.videoId] ?? 1;
    }
  }

  /// videoId 기준 중복 제거. 먼저 등장한 후보 유지.
  void _dedup(List<RecommendationCandidate> candidates) {
    final seen = <String>{};
    candidates.retainWhere((c) => seen.add(c.videoId));
  }

  /// 다운로드 완료·dismiss·비음악 콘텐츠 제거.
  void _filterOut(List<RecommendationCandidate> candidates) {
    candidates.removeWhere((c) {
      if (_downloadedVideoIds.contains(c.videoId)) return true;
      if (_dismissedVideoIds.contains(c.videoId)) return true;
      if (!_likelyMusic(c)) return true;
      return false;
    });
  }

  /// 비음악 콘텐츠 필터.
  bool _likelyMusic(RecommendationCandidate c) {
    if (c.duration != null) {
      if (c.duration!.inSeconds < _minDurationSec) return false;
      if (c.duration!.inMinutes > _maxDurationMin) return false;
    }

    if (_nonMusicPattern.hasMatch(c.title)) return false;

    return true;
  }

  /// 점수 산정.
  void _score(List<RecommendationCandidate> candidates) {
    for (final c in candidates) {
      double score = 0;

      // 소스 기본 점수
      switch (c.source) {
        case RecommendationSource.related:
          score += _scoreRelated;
        case RecommendationSource.channel:
          score += _scoreChannel;
        case RecommendationSource.search:
          score += _scoreSearch;
      }

      // 재생 시간 보정
      if (c.duration != null) {
        final mins = c.duration!.inSeconds / 60;
        if (mins >= 1 && mins <= 7) {
          score += _scoreDurationIdeal;
        } else if (mins > 7 && mins <= 15) {
          score += _scoreDurationMedium;
        }
      }

      // 복수 전략 중복 가산
      if (c.duplicateCount >= 2) {
        score += (c.duplicateCount - 1) * _scoreDuplicateBonus;
      }

      c.score = score;
    }
  }

  /// [RecommendationCandidate]를 소스별 사유와 함께 [Recommendation]으로 변환.
  Recommendation _toRecommendation(RecommendationCandidate c) {
    final reason = switch (c.source) {
      RecommendationSource.related => _buildRelatedReason(c.sourceVideoId!),
      RecommendationSource.channel => '${c.channelName}의 최신곡',
      RecommendationSource.search => '회원님이 좋아할 만한 곡',
    };

    return c.toRecommendation(reason);
  }

  /// 관련 영상 추천 사유 생성.
  String _buildRelatedReason(String sourceVideoId) {
    final title = _downloadedTitleMap[sourceVideoId];
    if (title != null) {
      final short = title.length > 20 ? '${title.substring(0, 20)}...' : title;
      return "'$short'과(와) 비슷한 곡";
    }
    return '비슷한 곡 추천';
  }
}
