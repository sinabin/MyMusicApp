import '../../models/download_item.dart';
import '../../models/playback_record.dart';

/// 시드 추출 결과 데이터.
class SeedData {
  /// 최근 다운로드 1건의 videoId.
  final String? recentVideoId;

  /// channelId 빈도 1위.
  final String? topChannelId;

  /// 메타데이터 기반 검색 쿼리.
  final String? searchQuery;

  const SeedData({
    this.recentVideoId,
    this.topChannelId,
    this.searchQuery,
  });
}

/// 다운로드 이력에서 추천 시드를 추출하는 분석기.
///
/// [RecommendationService]에서 파이프라인 첫 단계로 호출.
/// [DownloadItem]의 메타데이터를 분석하여 [SeedData] 생성.
class SeedAnalyzer {
  /// 다운로드 이력에서 추천 시드 추출.
  SeedData analyze(List<DownloadItem> history) {
    return SeedData(
      recentVideoId: _pickRecentVideoId(history),
      topChannelId: _pickTopChannel(history),
      searchQuery: _buildSearchQuery(history),
    );
  }

  /// 재생 기록 가중치를 적용한 시드 추출.
  ///
  /// [playbackRecords]의 재생 빈도가 높은 아티스트/채널에 가중치를 부여하여
  /// 보다 정확한 추천 시드 생성.
  SeedData analyzeWeighted(
    List<DownloadItem> history,
    List<PlaybackRecord> playbackRecords,
  ) {
    if (playbackRecords.isEmpty) return analyze(history);

    // 재생 빈도 계산: videoId → 재생 횟수
    final playCount = <String, int>{};
    for (final record in playbackRecords) {
      playCount.update(record.videoId, (v) => v + 1, ifAbsent: () => 1);
    }

    // 가중치 적용된 이력 정렬: 재생 횟수 높은 곡 우선
    final weighted = List<DownloadItem>.from(history)
      ..sort((a, b) {
        final countA = playCount[a.videoId] ?? 0;
        final countB = playCount[b.videoId] ?? 0;
        return countB.compareTo(countA);
      });

    return SeedData(
      recentVideoId: _pickRecentVideoId(history),
      topChannelId: _pickWeightedTopChannel(history, playCount),
      searchQuery: _buildWeightedSearchQuery(weighted),
    );
  }

  /// 재생 빈도 가중치를 적용한 최빈 채널 반환.
  String? _pickWeightedTopChannel(
    List<DownloadItem> history,
    Map<String, int> playCount,
  ) {
    final channelScore = <String, double>{};
    for (final item in history) {
      if (item.channelId == null) continue;
      final weight = (playCount[item.videoId] ?? 0) + 1.0;
      channelScore.update(
        item.channelId!,
        (v) => v + weight,
        ifAbsent: () => weight,
      );
    }
    if (channelScore.isEmpty) return null;
    return (channelScore.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  /// 재생 빈도 가중치를 적용한 검색 쿼리 생성.
  String? _buildWeightedSearchQuery(List<DownloadItem> weighted) {
    return _buildSearchQuery(weighted);
  }

  /// 최근 다운로드 1건의 videoId 반환.
  String? _pickRecentVideoId(List<DownloadItem> history) {
    if (history.isEmpty) return null;
    return history.first.videoId;
  }

  /// channelId 빈도 1위 반환.
  String? _pickTopChannel(List<DownloadItem> history) {
    final channels = history
        .where((e) => e.channelId != null)
        .map((e) => e.channelId!)
        .toList();
    if (channels.isEmpty) return null;
    return _mostFrequent(channels);
  }

  /// 검색 쿼리 생성. 우선순위: artistName > keywords > 파일명 폴백.
  String? _buildSearchQuery(List<DownloadItem> history) {
    // 1순위: artistName
    final artists = history
        .where((e) => e.artistName != null)
        .map((e) => e.artistName!)
        .toList();
    if (artists.isNotEmpty) {
      final topArtist = _mostFrequent(artists);
      return '$topArtist music';
    }

    // 2순위: keywords
    final allKeywords =
        history.expand((e) => e.keywords ?? <String>[]).toList();
    if (allKeywords.isNotEmpty) {
      final top2 = _topN(allKeywords, 2);
      return '${top2.join(' ')} music';
    }

    // 3순위 (폴백): 파일명 파싱
    return _fallbackFileNameParsing(history);
  }

  /// 파일명에서 검색 쿼리 추출 (레거시 레코드 전용).
  String? _fallbackFileNameParsing(List<DownloadItem> items) {
    final stopWords = {
      'official', 'mv', 'audio', 'lyrics', 'hd', '4k',
      'music', 'video', 'ver', 'version', 'feat', 'ft',
    };

    final wordFreq = <String, int>{};
    for (final item in items.take(10)) {
      final name = item.fileName
          .replaceAll(RegExp(r'\.\w+$'), '')
          .replaceAll(RegExp(r'[(\[\{【].*?[)\]\}】]'), '')
          .replaceAll(RegExp(r'\d{2,}'), '')
          .split(RegExp(r'[\s\-_,|·]+'));

      for (final word in name) {
        final clean = word.trim();
        if (clean.length >= 2 &&
            !stopWords.contains(clean.toLowerCase())) {
          wordFreq.update(clean, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    if (wordFreq.isEmpty) return null;
    final topWord = (wordFreq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
    return '$topWord music';
  }

  /// 리스트에서 최빈값 반환.
  String _mostFrequent(List<String> items) {
    final freq = <String, int>{};
    for (final item in items) {
      freq.update(item, (v) => v + 1, ifAbsent: () => 1);
    }
    return (freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  /// 리스트에서 빈도 상위 [n]개 반환.
  List<String> _topN(List<String> items, int n) {
    final freq = <String, int>{};
    for (final item in items) {
      freq.update(item, (v) => v + 1, ifAbsent: () => 1);
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }
}
