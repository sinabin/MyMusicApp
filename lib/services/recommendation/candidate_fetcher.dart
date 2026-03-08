import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../models/recommendation.dart';
import '../../models/recommendation_candidate.dart';
import '../youtube_service.dart';
import 'seed_analyzer.dart';

/// 3개 전략을 병렬 실행하여 추천 후보를 수집하는 페처.
///
/// [YouTubeService]를 통해 관련 영상·채널 업로드·검색 결과를 조합.
/// 개별 전략 실패 시 해당 전략만 건너뛰고 나머지 결과 반환.
class CandidateFetcher {
  final YouTubeService _yt;

  CandidateFetcher(this._yt);

  /// 3개 전략을 병렬 실행하여 후보 수집.
  Future<List<RecommendationCandidate>> fetch(SeedData seeds) async {
    final results = await Future.wait<List<RecommendationCandidate>>([
      if (seeds.recentVideoId != null)
        _strategyRelated(seeds.recentVideoId!).catchError((e) {
          debugPrint('[CandidateFetcher] Related strategy failed: $e');
          return <RecommendationCandidate>[];
        }),
      if (seeds.topChannelId != null)
        _strategyChannel(seeds.topChannelId!).catchError((e) {
          debugPrint('[CandidateFetcher] Channel strategy failed: $e');
          return <RecommendationCandidate>[];
        }),
      if (seeds.searchQuery != null)
        _strategySearch(seeds.searchQuery!).catchError((e) {
          debugPrint('[CandidateFetcher] Search strategy failed: $e');
          return <RecommendationCandidate>[];
        }),
    ]);

    return results.expand((list) => list).toList();
  }

  /// 전략 A: 시드 곡의 관련 영상에서 상위 10곡 수집.
  Future<List<RecommendationCandidate>> _strategyRelated(
    String videoId,
  ) async {
    final video = await _yt.getVideo(videoId);
    final related = await _yt.getRelatedVideos(video);
    if (related == null) return [];

    return related.take(10).map((v) => _fromVideo(
      v,
      source: RecommendationSource.related,
      sourceVideoId: videoId,
    )).toList();
  }

  /// 전략 B: 최빈 채널의 최신 업로드에서 상위 10곡 수집.
  Future<List<RecommendationCandidate>> _strategyChannel(
    String channelId,
  ) async {
    final uploads = await _yt.getChannelUploads(
      channelId,
      videoSorting: VideoSorting.newest,
    );

    return uploads.take(10).map((v) => _fromVideo(
      v,
      source: RecommendationSource.channel,
      sourceChannelId: channelId,
    )).toList();
  }

  /// 전략 C: 메타데이터 기반 검색어로 상위 10곡 수집.
  Future<List<RecommendationCandidate>> _strategySearch(
    String query,
  ) async {
    final results = await _yt.searchVideos(query);

    return results.take(10).map((v) => _fromVideo(
      v,
      source: RecommendationSource.search,
      sourceQuery: query,
    )).toList();
  }

  /// [Video]를 [RecommendationCandidate]로 변환.
  RecommendationCandidate _fromVideo(
    Video v, {
    required RecommendationSource source,
    String? sourceVideoId,
    String? sourceChannelId,
    String? sourceQuery,
  }) {
    return RecommendationCandidate(
      videoId: v.id.value,
      title: v.title,
      channelName: v.author,
      channelId: v.channelId.value,
      duration: v.duration,
      thumbnailUrl: v.thumbnails.highResUrl,
      source: source,
      sourceVideoId: sourceVideoId,
      sourceChannelId: sourceChannelId,
      sourceQuery: sourceQuery,
    );
  }
}
