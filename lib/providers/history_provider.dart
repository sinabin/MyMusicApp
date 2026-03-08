import 'package:flutter/foundation.dart';
import '../data/download_history_db.dart';
import '../models/download_item.dart';

class HistoryProvider extends ChangeNotifier {
  final DownloadHistoryDb _db;
  List<DownloadItem> _items = [];

  HistoryProvider({required DownloadHistoryDb db}) : _db = db;

  List<DownloadItem> get items => _items;
  int get count => _items.length;

  void loadHistory() {
    _items = _db.getAll();
    notifyListeners();
  }

  Future<void> addItem(DownloadItem item) async {
    await _db.add(item);
    _items = _db.getAll();
    notifyListeners();
  }

  Future<void> removeItem(int index) async {
    await _db.remove(index);
    _items = _db.getAll();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _db.clear();
    _items = [];
    notifyListeners();
  }
}
