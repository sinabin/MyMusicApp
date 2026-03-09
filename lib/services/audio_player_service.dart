import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/download_item.dart';
import '../models/queue_state.dart';
import 'audio_handler.dart';

/// 재생 큐·상태를 소유하는 단일 진실 원천 서비스.
///
/// [MyAudioHandler]를 래핑하며, 파일 검증·큐 관리·[DownloadItem]↔[MediaItem]
/// 매핑을 이 레이어에서만 수행. [PlayerProvider]는 스트림만 구독.
class AudioPlayerService {
  final MyAudioHandler _handler;

  /// 큐의 유일한 소유자.
  List<DownloadItem> _queue = [];

  final StreamController<QueueState> _queueStateController =
      StreamController<QueueState>.broadcast();

  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration?>? _durationSub;

  /// 캐싱된 재생 여부 스트림. getter 호출마다 새 스트림 생성 방지.
  late final Stream<bool> _playingStream =
      _handler.player.playerStateStream.map(
        (state) =>
            state.playing &&
            state.processingState != ProcessingState.completed,
      );

  AudioPlayerService(this._handler) {
    _listenToIndex();
    _listenToDuration();
  }

  // ─── Streams ───────────────────────────────────────────────

  /// 큐·인덱스·현재 트랙을 번들로 발행하는 스트림.
  Stream<QueueState> get queueStateStream => _queueStateController.stream;

  /// 재생 여부 스트림.
  Stream<bool> get playingStream => _playingStream;

  /// 현재 재생 위치 스트림.
  Stream<Duration> get positionStream => _handler.player.positionStream;

  /// 곡 전체 길이 스트림.
  Stream<Duration?> get durationStream => _handler.player.durationStream;

  /// 루프 모드 스트림.
  Stream<LoopMode> get loopModeStream => _handler.player.loopModeStream;

  /// 셔플 모드 스트림.
  Stream<bool> get shuffleModeEnabledStream =>
      _handler.player.shuffleModeEnabledStream;

  // ─── Commands ──────────────────────────────────────────────

  /// [items] 목록을 큐로 설정하고 [startIndex]부터 재생.
  ///
  /// 스트리밍 항목은 파일 검증을 건너뛰고, 로컬 파일은 존재 여부 확인.
  /// [setAudioSource] 후 명시적으로 [QueueState]를 발행하여
  /// [currentIndexStream]의 distinct 필터로 인한 누락을 방지.
  Future<void> playQueue(
    List<DownloadItem> items, {
    int startIndex = 0,
  }) async {
    final validItems = items
        .where((item) =>
            item.isStreaming || File(item.filePath).existsSync())
        .toList();
    if (validItems.isEmpty) return;

    var adjustedIndex = 0;
    if (startIndex > 0 && startIndex < items.length) {
      final target = items[startIndex];
      adjustedIndex = validItems.indexOf(target);
      if (adjustedIndex < 0) adjustedIndex = 0;
    }

    _queue = validItems;

    final mediaItems = validItems.map(_toMediaItem).toList();
    await _handler.setAudioSource(mediaItems, initialIndex: adjustedIndex);
    // currentIndexStream은 동일 인덱스(예: 0→0)에 대해 이벤트를 발행하지
    // 않으므로(distinct), 큐 교체 시 반드시 명시적으로 QueueState 발행.
    _emitQueueState(adjustedIndex);
    await _handler.play();
  }

  /// 단일 곡 재생.
  Future<void> playSingle(DownloadItem item) => playQueue([item]);

  /// 재생 시작.
  Future<void> play() => _handler.play();

  /// 일시정지.
  Future<void> pause() => _handler.pause();

  /// 정지 및 큐 초기화.
  Future<void> stop() async {
    await _handler.stop();
    _queue = [];
    _emitQueueState(-1);
  }

  /// [position]으로 탐색.
  Future<void> seek(Duration position) => _handler.seek(position);

  /// 다음 곡으로 이동.
  Future<void> seekToNext() => _handler.skipToNext();

  /// 이전 곡으로 이동.
  Future<void> seekToPrevious() => _handler.skipToPrevious();

  /// 큐 내 [index] 위치의 곡으로 이동 후 재생.
  Future<void> seekToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _handler.skipToQueueItem(index);
    await _handler.play();
  }

  /// 큐에 곡 추가.
  ///
  /// addQueueItem은 currentIndex를 변경하지 않으므로 명시적 emit 필요.
  Future<void> addToQueue(DownloadItem item) async {
    if (!item.isStreaming && !File(item.filePath).existsSync()) return;
    final prevQueue = _queue;
    _queue = [..._queue, item];
    try {
      await _handler.addQueueItem(_toMediaItem(item));
    } catch (_) {
      _queue = prevQueue;
      rethrow;
    }
    _emitCurrentQueueState();
  }

  /// 큐에서 [index] 위치의 곡 제거.
  ///
  /// _queue를 핸들러보다 먼저 갱신해야 await 중 [_listenToIndex]가
  /// 인덱스 이동 이벤트를 수신할 때 올바른 큐를 참조.
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final prevQueue = _queue;
    _queue = [..._queue]..removeAt(index);
    try {
      await _handler.removeQueueItemAt(index);
    } catch (_) {
      _queue = prevQueue;
      rethrow;
    }
    _emitCurrentQueueState();
  }

  /// 큐 내 아이템 순서 변경.
  ///
  /// _queue를 핸들러보다 먼저 갱신해야 await 중 [_listenToIndex]가
  /// 인덱스 이동 이벤트를 수신할 때 올바른 큐를 참조.
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;
    final prevQueue = _queue;
    final newQueue = [..._queue];
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);
    _queue = newQueue;
    try {
      await _handler.moveQueueItem(oldIndex, newIndex);
    } catch (_) {
      _queue = prevQueue;
      rethrow;
    }
    _emitCurrentQueueState();
  }

  /// 셔플 모드 설정.
  Future<void> setShuffleMode(bool enabled) =>
      _handler.player.setShuffleModeEnabled(enabled);

  /// 루프 모드 설정.
  Future<void> setLoopMode(LoopMode mode) => _handler.player.setLoopMode(mode);

  // ─── Internal ──────────────────────────────────────────────

  /// just_audio의 currentIndex 변경을 감지하여 [QueueState] 발행.
  void _listenToIndex() {
    _indexSub = _handler.player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _emitQueueState(index);
      }
    });
  }

  /// duration 수신 시 현재 트랙에 lazy backfill 수행. 스트리밍 항목은 건너뜀.
  void _listenToDuration() {
    _durationSub = _handler.player.durationStream.listen((dur) {
      if (dur == null) return;
      final currentIndex = _handler.player.currentIndex;
      if (currentIndex == null ||
          currentIndex < 0 ||
          currentIndex >= _queue.length) {
        return;
      }
      final track = _queue[currentIndex];
      if (track.isStreaming) return;
      if (track.duration == null && track.isInBox) {
        track.durationInMs = dur.inMilliseconds;
        track.save();
      }
    });
  }

  void _emitQueueState(int index) {
    _queueStateController
        .add(QueueState(queue: List.unmodifiable(_queue), currentIndex: index));
  }

  /// 현재 just_audio 인덱스를 기반으로 [QueueState] 발행.
  void _emitCurrentQueueState() {
    final index = _handler.player.currentIndex ?? -1;
    final safeIndex =
        (index >= 0 && index < _queue.length) ? index : -1;
    _emitQueueState(safeIndex);
  }

  /// [DownloadItem]을 [MediaItem]으로 변환. 스트리밍 항목은 URL을 id로 사용.
  MediaItem _toMediaItem(DownloadItem item) {
    final title = item.fileName.endsWith('.m4a')
        ? item.fileName.substring(0, item.fileName.length - 4)
        : item.fileName;
    return MediaItem(
      id: item.isStreaming ? item.streamUrl! : item.filePath,
      title: title,
      artist: item.artistName ?? item.channelName ?? '',
      artUri: item.thumbnailUrl != null
          ? (item.thumbnailUrl!.startsWith('/')
              ? Uri.file(item.thumbnailUrl!)
              : Uri.parse(item.thumbnailUrl!))
          : null,
      duration: item.duration,
    );
  }

  /// 리소스 해제. [MyAudioHandler]의 네이티브 리소스도 함께 정리.
  Future<void> dispose() async {
    await _indexSub?.cancel();
    await _durationSub?.cancel();
    await _queueStateController.close();
    await _handler.dispose();
  }
}
