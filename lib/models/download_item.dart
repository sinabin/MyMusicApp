import 'package:hive/hive.dart';

part 'download_item.g.dart';

@HiveType(typeId: 0)
class DownloadItem extends HiveObject {
  @HiveField(0)
  final String fileName;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  final int fileSize;

  @HiveField(3)
  final DateTime downloadDate;

  @HiveField(4)
  final String videoId;

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
