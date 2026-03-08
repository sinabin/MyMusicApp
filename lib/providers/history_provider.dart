import 'package:flutter/foundation.dart';
import '../data/download_history_db.dart';
import '../models/download_item.dart';

/// 다운로드 기록 상태를 관리하는 Provider.
///
/// [DownloadHistoryDb]를 통해 기록을 조회·추가·삭제하며,
/// [HomeScreen]의 기록 목록에 데이터를 제공.
class HistoryProvider extends ChangeNotifier {
  final DownloadHistoryDb _db;
  List<DownloadItem> _items = [];

  HistoryProvider({required DownloadHistoryDb db}) : _db = db;

  /// 다운로드 기록 목록.
  List<DownloadItem> get items => _items;

  /// 기록 개수.
  int get count => _items.length;

  /// DB에서 전체 기록을 다시 불러와 갱신.
  void loadHistory() {
    _items = _db.getAll();
    notifyListeners();
  }

  /// [item]을 기록에 추가하고 목록 갱신.
  Future<void> addItem(DownloadItem item) async {
    await _db.add(item);
    _items = _db.getAll();
    notifyListeners();
  }

  /// [index] 위치의 기록 삭제 및 목록 갱신.
  Future<void> removeItem(int index) async {
    await _db.remove(index);
    _items = _db.getAll();
    notifyListeners();
  }

  /// 모든 기록 일괄 삭제.
  Future<void> clearHistory() async {
    await _db.clear();
    _items = [];
    notifyListeners();
  }
}
