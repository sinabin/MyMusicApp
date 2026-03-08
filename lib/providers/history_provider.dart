import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/download_history_db.dart';
import '../models/download_item.dart';

/// 다운로드 기록 상태를 관리하는 Provider.
///
/// [DownloadHistoryDb]를 통해 기록을 조회·추가·삭제하며,
/// [HomeScreen]의 기록 목록에 데이터를 제공.
/// 비동기 작업의 순차 실행을 보장하여 동시 접근 시 데이터 불일치 방지.
class HistoryProvider extends ChangeNotifier {
  final DownloadHistoryDb _db;
  List<DownloadItem> _items = [];
  Future<void> _lock = Future.value();

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

  /// 비동기 작업의 순차 실행을 보장하는 내부 동기화 래퍼.
  Future<void> _synchronized(Future<void> Function() fn) {
    return _lock = _lock.then((_) => fn());
  }

  /// [item]을 기록에 추가하고 목록 갱신.
  Future<void> addItem(DownloadItem item) {
    return _synchronized(() async {
      await _db.add(item);
      _items = _db.getAll();
      notifyListeners();
    });
  }

  /// [index] 위치의 기록 삭제 및 목록 갱신.
  Future<void> removeItem(int index) {
    return _synchronized(() async {
      await _db.remove(index);
      _items = _db.getAll();
      notifyListeners();
    });
  }

  /// 모든 기록 일괄 삭제.
  Future<void> clearHistory() {
    return _synchronized(() async {
      await _db.clear();
      _items = [];
      notifyListeners();
    });
  }
}
