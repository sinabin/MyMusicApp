import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/download_item.dart';
import '../models/queue_state.dart';
import '../services/audio_player_service.dart';

/// 재생 상태를 UI에 노출하는 순수 반응형 Provider.
///
/// 자체 상태를 갖지 않으며, [AudioPlayerService]의 스트림을 구독하여
/// 상태를 파생. 미니 플레이어·풀 플레이어 등에서 소비.
class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _service;
  final void Function(String videoId)? _onTrackPlayed;
  final List<StreamSubscription> _subscriptions = [];

  // ─── 스트림에서 파생되는 상태 ──────────────────────────────

  QueueState _queueState = QueueState.empty;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  // ─── UI 전용 상태 ──────────────────────────────────────────

  bool _isFullPlayerOpen = false;
  String? _lastPlayedVideoId;

  PlayerProvider({
    required AudioPlayerService audioPlayerService,
    void Function(String videoId)? onTrackPlayed,
  })  : _service = audioPlayerService,
        _onTrackPlayed = onTrackPlayed {
    _listenToStreams();
  }

  // ─── Getters (공개 API — 기존과 동일) ──────────────────────

  /// 현재 재생 중인 곡.
  DownloadItem? get currentTrack => _queueState.currentTrack;

  /// 현재 재생 큐.
  List<DownloadItem> get queue => _queueState.queue;

  /// 큐 내 현재 인덱스.
  int get currentIndex => _queueState.currentIndex;

  /// 재생 여부.
  bool get isPlaying => _isPlaying;

  /// 현재 재생 위치.
  Duration get position => _position;

  /// 곡 전체 길이.
  Duration get duration => _duration;

  /// 셔플 모드 활성 여부.
  bool get isShuffleEnabled => _isShuffleEnabled;

  /// 반복 모드.
  LoopMode get loopMode => _loopMode;

  /// 미니 플레이어 표시 여부. 현재 트랙 존재 시 표시.
  bool get isMiniPlayerVisible => _queueState.currentTrack != null;

  /// 현재 트랙이 스트리밍 재생 중인지 여부.
  bool get isCurrentTrackStreaming => currentTrack?.isStreaming ?? false;

  /// 풀 플레이어 화면 열림 여부.
  bool get isFullPlayerOpen => _isFullPlayerOpen;

  /// 풀 플레이어 화면 열림/닫힘 상태 설정.
  void setFullPlayerOpen(bool value) {
    _isFullPlayerOpen = value;
    notifyListeners();
  }

  // ─── Commands (서비스에 위임) ───────────────────────────────

  /// 단일 곡 재생.
  Future<void> playTrack(DownloadItem item) => _service.playSingle(item);

  /// 목록의 [startIndex]부터 전체 재생.
  Future<void> playAll(List<DownloadItem> items, {int startIndex = 0}) =>
      _service.playQueue(items, startIndex: startIndex);

  /// 일시정지.
  Future<void> pause() => _service.pause();

  /// 재생 재개.
  Future<void> resume() => _service.play();

  /// 정지 및 미니 플레이어 숨김.
  Future<void> stop() => _service.stop();

  /// [position]으로 탐색.
  Future<void> seekTo(Duration position) => _service.seek(position);

  /// 다음 곡 재생.
  Future<void> skipNext() => _service.seekToNext();

  /// 이전 곡 재생.
  Future<void> skipPrevious() => _service.seekToPrevious();

  /// 큐 내 [index] 위치의 곡으로 이동.
  Future<void> skipToIndex(int index) => _service.seekToIndex(index);

  /// 셔플 모드 토글.
  Future<void> toggleShuffle() =>
      _service.setShuffleMode(!_isShuffleEnabled);

  /// 반복 모드 순환 (off → all → one → off).
  Future<void> cycleLoopMode() {
    final next = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    return _service.setLoopMode(next);
  }

  /// 큐에 곡 추가.
  Future<void> addToQueue(DownloadItem item) => _service.addToQueue(item);

  /// 큐에서 [index] 위치의 곡 제거.
  Future<void> removeFromQueue(int index) => _service.removeFromQueue(index);

  /// 큐 내 아이템 순서 변경.
  Future<void> moveInQueue(int oldIndex, int newIndex) =>
      _service.moveQueueItem(oldIndex, newIndex);

  // ─── Stream Listeners ──────────────────────────────────────

  void _listenToStreams() {
    _subscriptions.add(
      _service.queueStateStream.listen((state) {
        _queueState = state;
        final track = state.currentTrack;
        if (track != null) {
          final videoId = track.videoId;
          if (videoId != _lastPlayedVideoId) {
            _lastPlayedVideoId = videoId;
            _onTrackPlayed?.call(videoId);
          }
        } else {
          // 큐가 비면(stop 등) seek bar 잔존 방지.
          _position = Duration.zero;
          _duration = Duration.zero;
        }
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _service.playingStream.listen((playing) {
        _isPlaying = playing;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _service.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _service.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _service.loopModeStream.listen((mode) {
        _loopMode = mode;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _service.shuffleModeEnabledStream.listen((enabled) {
        _isShuffleEnabled = enabled;
        notifyListeners();
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
