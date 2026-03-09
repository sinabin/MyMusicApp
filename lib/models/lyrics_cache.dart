import 'package:hive/hive.dart';

part 'lyrics_cache.g.dart';

/// 가사 캐시 모델.
///
/// LRCLIB API에서 조회한 가사를 Hive에 캐싱.
/// [LyricsDb]를 통해 영속 저장. [LyricsService]에서 캐시 우선 조회.
@HiveType(typeId: 4)
class LyricsCache extends HiveObject {
  /// 조회 키 (videoId).
  @HiveField(0)
  final String videoId;

  /// 곡 제목 (검색에 사용된 값).
  @HiveField(1)
  final String? trackName;

  /// 아티스트 이름 (검색에 사용된 값).
  @HiveField(2)
  final String? artistName;

  /// 가사 텍스트.
  @HiveField(3)
  final String? plainLyrics;

  /// 검색 실패 플래그 (재시도 방지).
  @HiveField(4)
  final bool notFound;

  /// 캐싱 일시.
  @HiveField(5)
  final DateTime cachedAt;

  LyricsCache({
    required this.videoId,
    this.trackName,
    this.artistName,
    this.plainLyrics,
    this.notFound = false,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();
}
