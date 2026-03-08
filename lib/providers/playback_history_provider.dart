import 'package:flutter/foundation.dart';
import '../data/download_history_db.dart';
import '../data/playback_history_db.dart';
import '../models/download_item.dart';
import '../models/playback_record.dart';
import '../utils/format_utils.dart';

/// 재생 기록 상태를 관리하는 Provider.
///
/// [PlaybackHistoryDb]를 통해 재생 기록을 관리하고,
/// [DownloadHistoryDb]를 참조하여 videoId → [DownloadItem] resolve 수행.
class PlaybackHistoryProvider extends ChangeNotifier {
  final PlaybackHistoryDb _db;
  final DownloadHistoryDb _downloadDb;
  String? _lastRecordedVideoId;

  PlaybackHistoryProvider({
    required PlaybackHistoryDb db,
    required DownloadHistoryDb downloadDb,
  })  : _db = db,
        _downloadDb = downloadDb;

  /// 곡 재생을 기록. 동일 곡 연속 기록 방지.
  Future<void> recordPlay(String videoId) async {
    if (videoId == _lastRecordedVideoId) return;

    // 중복 방지: 비동기 호출 전에 즉시 갱신.
    final prev = _lastRecordedVideoId;
    _lastRecordedVideoId = videoId;

    try {
      await _db.add(PlaybackRecord(
        videoId: videoId,
        playedAt: DateTime.now(),
      ));
      notifyListeners();
    } catch (e) {
      _lastRecordedVideoId = prev;
      rethrow;
    }
  }

  /// 최근 재생 곡 목록 반환 (중복 제거, [DownloadItem] resolve).
  List<DownloadItem> getRecentTracks(int limit) {
    final recentIds = _db.getRecentVideoIds(limit);
    final allDownloads = _downloadDb.getAll();
    final downloadMap = <String, DownloadItem>{};
    for (final item in allDownloads) {
      downloadMap[item.videoId] = item;
    }
    return recentIds
        .where((id) => downloadMap.containsKey(id))
        .map((id) => downloadMap[id]!)
        .toList();
  }

  /// 최근 재생 곡 수 반환.
  int get recentCount => _db.getRecentVideoIds(100).length;

  /// 시간 구간별로 그룹화된 최근 재생 곡 반환.
  Map<String, List<DownloadItem>> getGroupedRecentTracks({int limit = 50}) {
    final allRecords = _db.getAll();
    final allDownloads = _downloadDb.getAll();
    final downloadMap = <String, DownloadItem>{};
    for (final item in allDownloads) {
      downloadMap[item.videoId] = item;
    }

    final grouped = <String, List<DownloadItem>>{};
    final seen = <String>{};

    for (final record in allRecords) {
      if (seen.length >= limit) break;
      if (!seen.add(record.videoId)) continue;
      final item = downloadMap[record.videoId];
      if (item == null) continue;

      final label = FormatUtils.timeGroupLabel(record.playedAt);
      grouped.putIfAbsent(label, () => []).add(item);
    }

    return grouped;
  }

  /// 모든 재생 기록 삭제.
  Future<void> clearHistory() async {
    await _db.clear();
    _lastRecordedVideoId = null;
    notifyListeners();
  }
}
