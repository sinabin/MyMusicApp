import 'package:flutter/foundation.dart';
import '../../models/recommendation.dart';
import '../youtube_service.dart';

/// 시기별 트렌딩 음악을 검색하여 추천 목록을 생성하는 페처.
///
/// [YouTubeService]를 통해 트렌딩 검색어로 인기 음악을 수집하며,
/// [RecommendationService]에서 섹션별 추천 생성 시 호출.
class TrendingFetcher {
  final YouTubeService _yt;

  TrendingFetcher(this._yt);

  /// 트렌딩 음악 최대 10건 조회.
  Future<List<Recommendation>> fetchTrending() async {
    final year = DateTime.now().year;
    final queries = [
      'trending music $year',
      '인기차트 $year',
    ];

    final results = <Recommendation>[];
    final seen = <String>{};

    for (final query in queries) {
      try {
        final searchResults = await _yt.searchVideos(query);
        for (final v in searchResults.take(8)) {
          if (seen.add(v.id.value)) {
            results.add(Recommendation(
              videoId: v.id.value,
              title: v.title,
              channelName: v.author,
              channelId: v.channelId.value,
              duration: v.duration,
              thumbnailUrl: v.thumbnails.highResUrl,
              source: RecommendationSource.trending,
              reason: '지금 인기 있는 곡',
            ));
          }
          if (results.length >= 10) break;
        }
      } catch (e) {
        debugPrint('[TrendingFetcher] Query "$query" failed: $e');
      }
      if (results.length >= 10) break;
    }
    return results;
  }
}
