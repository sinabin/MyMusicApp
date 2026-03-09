import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/dismissed_recommendation_db.dart';
import '../../data/download_history_db.dart';
import '../../data/playback_history_db.dart';
import '../../models/recommendation.dart';
import '../../models/sectioned_recommendations.dart';
import '../youtube_service.dart';
import 'candidate_fetcher.dart';
import 'candidate_ranker.dart';
import 'seed_analyzer.dart';
import 'trending_fetcher.dart';

/// 추천 파이프라인을 조율하는 서비스.
///
/// [SeedAnalyzer]·[CandidateFetcher]·[CandidateRanker]를 순서대로 실행하여
/// 최종 추천 목록을 생성. 이력 3건 미만 시 [_coldStartFallback] 실행.
class RecommendationService {
  final YouTubeService _yt;
  final DownloadHistoryDb _historyDb;
  final DismissedRecommendationDb _dismissedDb;
  final SeedAnalyzer _seedAnalyzer = SeedAnalyzer();
  late final CandidateFetcher _candidateFetcher;
  late final TrendingFetcher _trendingFetcher;

  RecommendationService({
    required YouTubeService youtubeService,
    required DownloadHistoryDb downloadHistoryDb,
    required DismissedRecommendationDb dismissedDb,
  })  : _yt = youtubeService,
        _historyDb = downloadHistoryDb,
        _dismissedDb = dismissedDb {
    _candidateFetcher = CandidateFetcher(_yt);
    _trendingFetcher = TrendingFetcher(_yt);
  }

  /// 추천 목록 생성. 이력 3건 미만 시 폴백 사용.
  Future<List<Recommendation>> buildRecommendations() async {
    final history = _historyDb.getAll();

    if (history.length < 3) {
      return _coldStartFallback(history);
    }

    // 정상 파이프라인
    final seeds = _seedAnalyzer.analyze(history);
    final candidates = await _candidateFetcher.fetch(seeds);

    final downloadedVideoIds = history.map((e) => e.videoId).toSet();
    final dismissedVideoIds = _dismissedDb.getAllVideoIds();
    final titleMap = {
      for (final item in history)
        item.videoId: item.fileName.replaceAll(RegExp(r'\.\w+$'), ''),
    };

    final ranker = CandidateRanker(
      downloadedVideoIds: downloadedVideoIds,
      dismissedVideoIds: dismissedVideoIds,
      downloadedTitleMap: titleMap,
    );

    return ranker.rank(candidates);
  }

  /// Cold start 폴백. 이력 0건 시 트렌딩 검색, 1~2건 시 관련 영상.
  Future<List<Recommendation>> _coldStartFallback(
    List<dynamic> history,
  ) async {
    if (history.isEmpty) {
      return _trendingFallback();
    }

    return _relatedFallback(history.first.videoId);
  }

  /// 트렌딩 음악 검색 폴백.
  Future<List<Recommendation>> _trendingFallback() async {
    try {
      final results = await _yt.searchVideos(
        'trending music ${DateTime.now().year}',
      );
      return results.take(10).map((v) => _videoToRecommendation(
        v,
        source: RecommendationSource.search,
        reason: '인기 음악',
      )).toList();
    } catch (e) {
      debugPrint('[RecommendationService] Trending fallback failed: $e');
      return [];
    }
  }

  /// 첫 곡의 관련 영상 폴백.
  Future<List<Recommendation>> _relatedFallback(String videoId) async {
    try {
      final video = await _yt.getVideo(videoId);
      final related = await _yt.getRelatedVideos(video);
      if (related == null) return [];

      return related.take(15).map((v) => _videoToRecommendation(
        v,
        source: RecommendationSource.related,
        reason: '비슷한 곡 추천',
      )).toList();
    } catch (e) {
      debugPrint('[RecommendationService] Related fallback failed: $e');
      return [];
    }
  }

  /// 트렌딩 추천 목록 조회.
  Future<List<Recommendation>> fetchTrending() => _trendingFetcher.fetchTrending();

  /// 섹션별 추천 생성 (forYou + trending + similarSongs 병렬 실행).
  Future<SectionedRecommendations> buildSectionedRecommendations(
    PlaybackHistoryDb playbackHistoryDb,
  ) async {
    final history = _historyDb.getAll();

    final results = await Future.wait([
      // forYou: 기존 파이프라인
      buildRecommendations(),
      // trending
      _trendingFetcher.fetchTrending(),
      // similarSongs: related 전략만
      _buildSimilarSongs(history),
    ]);

    return SectionedRecommendations(
      forYou: results[0],
      trending: results[1],
      similarSongs: results[2],
    );
  }

  /// 최근 곡의 관련 영상으로 유사곡 목록 생성.
  Future<List<Recommendation>> _buildSimilarSongs(
    List<dynamic> history,
  ) async {
    if (history.isEmpty) return [];
    try {
      // 가장 최근 다운로드 2곡의 관련 영상
      final futures = history.take(2).map((item) async {
        try {
          final videoId = item.videoId as String;
          final fileName = item.fileName as String;
          final video = await _yt.getVideo(videoId);
          final related = await _yt.getRelatedVideos(video);
          final cleanName = fileName.replaceAll(RegExp(r'\.\w+$'), '');
          return related
                  ?.take(5)
                  .map((v) => _videoToRecommendation(
                        v,
                        source: RecommendationSource.related,
                        reason: "'$cleanName'과(와) 비슷한 곡",
                      ))
                  .toList() ??
              <Recommendation>[];
        } catch (e) {
          debugPrint('[RecommendationService] Similar songs fetch failed: $e');
          return <Recommendation>[];
        }
      });
      final lists = await Future.wait(futures);
      final all = lists.expand((e) => e).toList();
      // 중복 제거
      final seen = <String>{};
      all.retainWhere((r) => seen.add(r.videoId));
      return all.take(10).toList();
    } catch (e) {
      debugPrint('[RecommendationService] buildSimilarSongs failed: $e');
      return [];
    }
  }

  /// [Video]를 [Recommendation]으로 변환.
  Recommendation _videoToRecommendation(
    Video v, {
    required RecommendationSource source,
    required String reason,
  }) {
    return Recommendation(
      videoId: v.id.value,
      title: v.title,
      channelName: v.author,
      channelId: v.channelId.value,
      duration: v.duration,
      thumbnailUrl: v.thumbnails.highResUrl,
      source: source,
      reason: reason,
    );
  }
}
