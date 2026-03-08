import '../models/download_item.dart';

/// 재생 큐의 불변 스냅샷.
///
/// [AudioPlayerService]가 발행하고 [PlayerProvider]가 구독하는
/// 단일 진실 원천(single source of truth).
class QueueState {
  /// 현재 큐에 포함된 곡 목록.
  final List<DownloadItem> queue;

  /// 큐 내 현재 재생 인덱스. 비어 있으면 -1.
  final int currentIndex;

  /// 현재 재생 중인 곡. 큐가 비어 있으면 null.
  DownloadItem? get currentTrack =>
      currentIndex >= 0 && currentIndex < queue.length
          ? queue[currentIndex]
          : null;

  const QueueState({
    required this.queue,
    required this.currentIndex,
  });

  /// 빈 상태.
  static const empty = QueueState(queue: [], currentIndex: -1);
}
