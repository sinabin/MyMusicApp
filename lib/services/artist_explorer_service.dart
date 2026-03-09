import 'package:flutter/foundation.dart';

import '../models/artist_node.dart';
import '../models/download_item.dart';
import '../models/recommendation.dart';
import 'youtube_service.dart';

/// 아티스트 그래프를 구축하고 관련 아티스트를 탐색하는 서비스.
///
/// 다운로드 이력에서 아티스트를 그룹화하고, YouTube API를 통해
/// 인기곡 및 관련 아티스트를 조회.
class ArtistExplorerService {
  final YouTubeService _yt;

  ArtistExplorerService({required YouTubeService youtubeService})
      : _yt = youtubeService;

  /// 다운로드 이력에서 아티스트 목록 생성. 다운로드 수 순 정렬.
  List<ArtistNode> buildArtistList(List<DownloadItem> history) {
    final channelMap = <String, _ChannelAgg>{};

    for (final item in history) {
      if (item.channelId == null || item.channelName == null) continue;

      channelMap.update(
        item.channelId!,
        (agg) {
          agg.count++;
          if (agg.videoIds.length < 5) agg.videoIds.add(item.videoId);
          agg.thumbnailUrl ??= item.thumbnailUrl;
          return agg;
        },
        ifAbsent: () => _ChannelAgg(
          channelId: item.channelId!,
          name: item.artistName ?? item.channelName!,
          thumbnailUrl: item.thumbnailUrl,
          videoIds: [item.videoId],
        ),
      );
    }

    final artists = channelMap.values
        .map((agg) => ArtistNode(
              channelId: agg.channelId,
              name: agg.name,
              thumbnailUrl: agg.thumbnailUrl,
              downloadCount: agg.count,
              sampleVideoIds: agg.videoIds,
            ))
        .toList()
      ..sort((a, b) => b.downloadCount.compareTo(a.downloadCount));

    return artists;
  }

  /// 아티스트의 채널 업로드에서 인기곡 추천 목록 조회.
  Future<List<Recommendation>> getArtistTopTracks(String channelId) async {
    try {
      final uploads = await _yt.getChannelUploads(channelId);
      return uploads
          .take(15)
          .map((v) => Recommendation(
                videoId: v.id.value,
                title: v.title,
                channelName: v.author,
                channelId: v.channelId.value,
                duration: v.duration,
                thumbnailUrl: v.thumbnails.highResUrl,
                source: RecommendationSource.channel,
                reason: '아티스트 인기곡',
              ))
          .toList();
    } catch (e) {
      debugPrint('[ArtistExplorerService] getArtistTopTracks failed: $e');
      return [];
    }
  }

  /// 아티스트 이름으로 관련 아티스트 검색.
  Future<List<ArtistNode>> getRelatedArtists(String artistName) async {
    try {
      final results =
          await _yt.searchVideos('$artistName similar artists music');
      final channelMap = <String, ArtistNode>{};

      for (final v in results.take(20)) {
        final chId = v.channelId.value;
        if (!channelMap.containsKey(chId)) {
          channelMap[chId] = ArtistNode(
            channelId: chId,
            name: v.author,
            thumbnailUrl: v.thumbnails.highResUrl,
            downloadCount: 0,
            sampleVideoIds: [v.id.value],
          );
        }
      }

      return channelMap.values.take(8).toList();
    } catch (e) {
      debugPrint('[ArtistExplorerService] getRelatedArtists failed: $e');
      return [];
    }
  }
}

/// 채널별 집계 데이터.
class _ChannelAgg {
  final String channelId;
  final String name;
  String? thumbnailUrl;
  int count = 1;
  final List<String> videoIds;

  _ChannelAgg({
    required this.channelId,
    required this.name,
    this.thumbnailUrl,
    required this.videoIds,
  });
}
