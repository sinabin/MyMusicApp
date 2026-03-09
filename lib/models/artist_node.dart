/// 아티스트 노드 모델.
///
/// 다운로드 이력에서 추출한 아티스트 정보를 표현.
/// [ArtistExplorerService]에서 생성, [ArtistExplorerScreen]에서 표시.
class ArtistNode {
  /// 채널 ID.
  final String channelId;

  /// 아티스트/채널 이름.
  final String name;

  /// 썸네일 URL.
  final String? thumbnailUrl;

  /// 다운로드 횟수.
  final int downloadCount;

  /// 다운로드된 곡의 videoId 샘플.
  final List<String> sampleVideoIds;

  const ArtistNode({
    required this.channelId,
    required this.name,
    this.thumbnailUrl,
    required this.downloadCount,
    this.sampleVideoIds = const [],
  });
}
