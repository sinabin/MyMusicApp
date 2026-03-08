import 'package:hive_flutter/hive_flutter.dart';
import '../models/download_item.dart';
import '../utils/constants.dart';

/// [DownloadItem]의 로컬 영속성을 담당하는 데이터베이스 레이어.
///
/// Hive(경량 NoSQL DB)를 사용하며, [HistoryProvider]가 이 클래스를
/// 주입받아 상태 관리를 수행.
class DownloadHistoryDb {
  Box<DownloadItem>? _box;

  /// Hive 초기화 및 [DownloadItem] 전용 Box 오픈.
  ///
  /// 다른 메서드 호출 전 반드시 완료 필요. `main.dart`에서 앱 시작 시 호출.
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DownloadItemAdapter());
    _box = await Hive.openBox<DownloadItem>(AppConstants.hiveDownloadBox);
  }

  /// 초기화된 Hive [Box] 반환.
  ///
  /// [init] 미호출 상태에서 접근 시 [StateError] 발생.
  Box<DownloadItem> get box {
    if (_box == null) {
      throw StateError('DownloadHistoryDb not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 저장된 모든 [DownloadItem]을 최신 다운로드순으로 반환.
  List<DownloadItem> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
  }

  /// [item]을 다운로드 기록에 추가.
  ///
  /// 동일 [filePath]가 이미 존재하면 중복 등록하지 않고 기존 항목 반환.
  Future<DownloadItem?> add(DownloadItem item) async {
    final existing = box.values.cast<DownloadItem?>().firstWhere(
          (e) => e!.filePath == item.filePath,
          orElse: () => null,
        );
    if (existing != null) return existing;
    await box.add(item);
    return null;
  }

  /// [index] 위치의 다운로드 기록 삭제.
  Future<void> remove(int index) async {
    await box.deleteAt(index);
  }

  /// 모든 다운로드 기록 일괄 삭제.
  Future<void> clear() async {
    await box.clear();
  }

  /// 저장된 다운로드 기록의 총 개수.
  int get count => box.length;
}
