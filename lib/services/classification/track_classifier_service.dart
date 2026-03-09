import '../../models/download_item.dart';
import 'keyword_dictionary.dart';

/// 다운로드 곡을 카테고리별로 분류하는 서비스.
///
/// [KeywordDictionary]의 키워드를 [DownloadItem]의 메타데이터와 매칭하여
/// 곡을 8개 카테고리로 분류.
class TrackClassifierService {
  /// 단일 곡의 카테고리 분류. threshold 이상 매칭된 카테고리 목록 반환.
  List<String> classify(DownloadItem item) {
    final text = _buildSearchText(item).toLowerCase();
    final matched = <String>[];

    for (final entry in KeywordDictionary.categories.entries) {
      final category = entry.key;
      final keywords = entry.value;
      int matchCount = 0;

      for (final keyword in keywords) {
        if (text.contains(keyword.toLowerCase())) {
          matchCount++;
        }
      }

      // threshold: 키워드 수 대비 10% 이상 매칭
      if (matchCount > 0 && matchCount / keywords.length >= 0.1) {
        matched.add(category);
      }
    }

    return matched;
  }

  /// 전체 곡을 카테고리별로 그룹화.
  Map<String, List<DownloadItem>> classifyAll(List<DownloadItem> items) {
    final result = <String, List<DownloadItem>>{};

    for (final item in items) {
      final categories = classify(item);
      for (final category in categories) {
        result.putIfAbsent(category, () => []).add(item);
      }
    }

    return result;
  }

  /// 곡의 메타데이터를 결합한 검색 텍스트 생성.
  String _buildSearchText(DownloadItem item) {
    final parts = <String>[
      item.fileName,
      if (item.artistName != null) item.artistName!,
      if (item.channelName != null) item.channelName!,
      if (item.keywords != null) item.keywords!.join(' '),
    ];
    return parts.join(' ');
  }
}
