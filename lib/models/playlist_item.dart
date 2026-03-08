import 'package:hive/hive.dart';

part 'playlist_item.g.dart';

/// 사용자 생성 플레이리스트 모델.
///
/// Hive에 영속 저장되며, [PlaylistDb]를 통해 CRUD 수행.
/// [trackVideoIds]로 곡 목록을 참조하고, [DownloadHistoryDb]에서 실제 곡 정보 resolve.
@HiveType(typeId: 2)
class PlaylistItem extends HiveObject {
  /// 고유 식별자 (밀리초 타임스탬프 기반).
  @HiveField(0)
  String id;

  /// 플레이리스트 이름.
  @HiveField(1)
  String name;

  /// 생성 일시.
  @HiveField(2)
  DateTime createdAt;

  /// 포함된 곡의 videoId 목록 (순서 보존).
  @HiveField(3)
  List<String> trackVideoIds;

  /// 대표 썸네일 URL.
  @HiveField(4)
  String? thumbnailUrl;

  /// 플레이리스트 설명.
  @HiveField(5)
  String? description;

  PlaylistItem({
    required this.id,
    required this.name,
    required this.createdAt,
    List<String>? trackVideoIds,
    this.thumbnailUrl,
    this.description,
  }) : trackVideoIds = trackVideoIds ?? [];
}
