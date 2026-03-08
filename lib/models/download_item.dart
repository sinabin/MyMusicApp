import 'package:hive/hive.dart';

part 'download_item.g.dart';

/// 다운로드 완료된 MP3 파일의 기록 모델.
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

  DownloadItem({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.downloadDate,
    required this.videoId,
    this.thumbnailUrl,
  });
}
