import 'package:hive_flutter/hive_flutter.dart';
import '../models/download_item.dart';
import '../utils/constants.dart';

class DownloadHistoryDb {
  Box<DownloadItem>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DownloadItemAdapter());
    _box = await Hive.openBox<DownloadItem>(AppConstants.hiveDownloadBox);
  }

  Box<DownloadItem> get box {
    if (_box == null) {
      throw StateError('DownloadHistoryDb not initialized. Call init() first.');
    }
    return _box!;
  }

  List<DownloadItem> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
  }

  Future<void> add(DownloadItem item) async {
    await box.add(item);
  }

  Future<void> remove(int index) async {
    await box.deleteAt(index);
  }

  Future<void> clear() async {
    await box.clear();
  }

  int get count => box.length;
}
