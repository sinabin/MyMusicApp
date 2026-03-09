import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/download_history_db.dart';
import '../data/local_storage.dart';
import '../models/download_item.dart';

/// 다운로드 기록 상태를 관리하는 Provider.
///
/// [DownloadHistoryDb]를 통해 기록을 조회·추가·삭제하며,
/// [HomeScreen]의 기록 목록과 Library의 전체 곡 목록에 데이터를 제공.
/// "Clear" 시 DB를 삭제하지 않고 타임스탬프 기반으로 HomeScreen에서만 숨김.
class HistoryProvider extends ChangeNotifier {
  final DownloadHistoryDb _db;
  final LocalStorage _localStorage;
  List<DownloadItem> _items = [];
  DateTime? _clearedAt;
  Future<void> _lock = Future.value();

  HistoryProvider({
    required DownloadHistoryDb db,
    required LocalStorage localStorage,
  })  : _db = db,
        _localStorage = localStorage;

  /// 전체 다운로드 기록 목록 (Library·Playlist용).
  List<DownloadItem> get items => _items;

  /// HomeScreen용 최근 다운로드 목록 (Clear 이후 다운로드분만).
  List<DownloadItem> get recentItems {
    if (_clearedAt == null) return _items;
    return _items
        .where((e) => e.downloadDate.isAfter(_clearedAt!))
        .toList();
  }

  /// 전체 기록 개수.
  int get count => _items.length;

  /// HomeScreen용 최근 기록 개수.
  int get recentCount => recentItems.length;

  /// 즐겨찾기 목록.
  List<DownloadItem> get favorites =>
      _items.where((e) => e.isFavorite).toList();

  /// [item]의 즐겨찾기 상태 토글.
  void toggleFavorite(DownloadItem item) {
    item.isFavorite = !item.isFavorite;
    item.save();
    notifyListeners();
  }

  /// DB에서 전체 기록과 Clear 타임스탬프를 불러와 갱신.
  Future<void> loadHistory() async {
    _items = _db.getAll();
    final clearedMs = await _localStorage.getHistoryClearedAt();
    if (clearedMs != null) {
      _clearedAt = DateTime.fromMillisecondsSinceEpoch(clearedMs);
    }
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

  /// [item]을 기록에서 삭제 및 목록 갱신.
  ///
  /// 메모리 리스트에서 즉시 제거 후 DB 삭제를 수행하여
  /// [Dismissible] 위젯 동기화 문제를 방지.
  void removeItem(DownloadItem item) {
    _items.remove(item);
    notifyListeners();
    _synchronized(() async {
      if (item.isInBox) {
        await item.delete();
      }
    });
  }

  /// HomeScreen의 최근 다운로드 목록만 숨김 (DB 유지).
  Future<void> clearRecent() {
    return _synchronized(() async {
      _clearedAt = DateTime.now();
      await _localStorage.setHistoryClearedAt(
        _clearedAt!.millisecondsSinceEpoch,
      );
      notifyListeners();
    });
  }
}
