import 'package:hive/hive.dart';

part 'download_item.g.dart';

/// 다운로드 완료된 오디오 파일의 기록 모델.
///
/// Hive에 영속 저장되며, [DownloadHistoryDb]를 통해 CRUD 수행.
/// [DownloadHistoryTile]에서 목록 항목으로 표시.
@HiveType(typeId: 0)
class DownloadItem extends HiveObject {
  /// 저장된 파일 이름(확장자 포함).
  @HiveField(0)
  final String fileName;

  /// 파일의 절대 경로.
  @HiveField(1)
  final String filePath;

  /// 파일 크기(바이트).
  @HiveField(2)
  final int fileSize;

  /// 다운로드 완료 일시.
  @HiveField(3)
  final DateTime downloadDate;

  /// 원본 YouTube 영상 ID.
  @HiveField(4)
  final String videoId;

  /// 원본 영상 썸네일 URL.
  @HiveField(5)
  final String? thumbnailUrl;

  /// 채널(업로더) 이름.
  @HiveField(6)
  final String? channelName;

  /// 채널 ID.
  @HiveField(7)
  final String? channelId;

  /// 영상 키워드 목록.
  @HiveField(8)
  final List<String>? keywords;

  /// 아티스트 이름 (musicData 기반).
  @HiveField(9)
  final String? artistName;

  /// 재생 시간(밀리초). 기존 데이터는 null, 최초 재생 시 backfill.
  @HiveField(10)
  int? durationInMs;

  /// 즐겨찾기 여부. 기존 데이터는 false.
  @HiveField(11)
  bool isFavorite;

  /// 재생 시간 [Duration] 반환.
  Duration? get duration =>
      durationInMs != null ? Duration(milliseconds: durationInMs!) : null;

  DownloadItem({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.downloadDate,
    required this.videoId,
    this.thumbnailUrl,
    this.channelName,
    this.channelId,
    this.keywords,
    this.artistName,
    this.durationInMs,
    this.isFavorite = false,
  });
}
