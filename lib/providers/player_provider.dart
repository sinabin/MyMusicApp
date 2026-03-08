import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/download_item.dart';
import '../services/audio_player_service.dart';

/// 재생 상태를 관리하는 Provider.
///
/// [AudioPlayerService]의 스트림을 구독하여 UI에 재생 상태를 노출.
/// 미니 플레이어·풀 플레이어에서 소비.
class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _service;
  final void Function(String videoId)? _onTrackPlayed;
  final List<StreamSubscription> _subscriptions = [];

  DownloadItem? _currentTrack;
  List<DownloadItem> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  bool _isMiniPlayerVisible = false;
  bool _isFullPlayerOpen = false;
  String? _lastPlayedVideoId;

  PlayerProvider({
    required AudioPlayerService audioPlayerService,
    void Function(String videoId)? onTrackPlayed,
  })  : _service = audioPlayerService,
        _onTrackPlayed = onTrackPlayed {
    _listenToStreams();
  }

  /// 현재 재생 중인 곡.
  DownloadItem? get currentTrack => _currentTrack;

  /// 현재 재생 큐.
  List<DownloadItem> get queue => _queue;

  /// 큐 내 현재 인덱스.
  int get currentIndex => _currentIndex;

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

  /// 미니 플레이어 표시 여부.
  bool get isMiniPlayerVisible => _isMiniPlayerVisible;

  /// 풀 플레이어 화면 열림 여부.
  bool get isFullPlayerOpen => _isFullPlayerOpen;

  /// 풀 플레이어 화면 열림/닫힘 상태 설정.
  void setFullPlayerOpen(bool value) {
    _isFullPlayerOpen = value;
    notifyListeners();
  }

  void _listenToStreams() {
    _subscriptions.add(
      _service.playerStateStream.listen((state) {
        _isPlaying = state.playing &&
            state.processingState != ProcessingState.completed;
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
        if (dur != null &&
            _currentTrack != null &&
            _currentTrack!.duration == null) {
          _backfillDuration(_currentTrack!, dur);
        }
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _service.currentIndexStream.listen((index) {
        if (index != null && index >= 0 && index < _queue.length) {
          _currentIndex = index;
          _currentTrack = _queue[index];
          _isMiniPlayerVisible = true;
          final videoId = _currentTrack!.videoId;
          if (videoId != _lastPlayedVideoId) {
            _lastPlayedVideoId = videoId;
            _onTrackPlayed?.call(videoId);
          }
          notifyListeners();
        }
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

  /// duration이 null인 [DownloadItem]에 [dur]을 저장 (lazy backfill).
  void _backfillDuration(DownloadItem item, Duration dur) {
    if (item.isInBox) {
      item.durationInMs = dur.inMilliseconds;
      item.save();
    }
  }

  /// 단일 곡 재생.
  Future<void> playTrack(DownloadItem item) async {
    if (!File(item.filePath).existsSync()) return;
    // 스트림 리스너가 올바른 큐를 참조하도록 setQueue 호출 전에 설정.
    _queue = [item];
    _currentIndex = 0;
    _currentTrack = item;
    _isMiniPlayerVisible = true;
    notifyListeners();
    await _service.setQueue([item]);
  }

  /// 목록의 [startIndex]부터 전체 재생.
  Future<void> playAll(List<DownloadItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;
    final validItems =
        items.where((item) => File(item.filePath).existsSync()).toList();
    if (validItems.isEmpty) return;
    var adjustedIndex = 0;
    if (startIndex > 0 && startIndex < items.length) {
      final target = items[startIndex];
      adjustedIndex = validItems.indexOf(target);
      if (adjustedIndex < 0) adjustedIndex = 0;
    }
    // 스트림 리스너가 올바른 큐를 참조하도록 setQueue 호출 전에 설정.
    _queue = validItems;
    _currentIndex = adjustedIndex;
    _currentTrack = validItems[adjustedIndex];
    _isMiniPlayerVisible = true;
    notifyListeners();
    await _service.setQueue(items, initialIndex: startIndex);
  }

  /// 일시정지.
  Future<void> pause() => _service.pause();

  /// 재생 재개.
  Future<void> resume() => _service.play();

  /// 정지 및 미니 플레이어 숨김.
  Future<void> stop() async {
    await _service.stop();
    _isMiniPlayerVisible = false;
    _currentTrack = null;
    _queue = [];
    _currentIndex = -1;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  /// [position]으로 탐색.
  Future<void> seekTo(Duration position) => _service.seek(position);

  /// 다음 곡 재생.
  Future<void> skipNext() => _service.seekToNext();

  /// 이전 곡 재생.
  Future<void> skipPrevious() => _service.seekToPrevious();

  /// 큐 내 [index] 위치의 곡으로 이동.
  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _service.seekToIndex(index);
  }

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
  Future<void> addToQueue(DownloadItem item) async {
    await _service.addToQueue(item);
    if (File(item.filePath).existsSync()) {
      _queue = [..._queue, item];
      notifyListeners();
    }
  }

  /// 큐에서 [index] 위치의 곡 제거.
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _service.removeFromQueue(index);
    _queue = [..._queue]..removeAt(index);
    if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.isEmpty ? -1 : _queue.length - 1;
    }
    notifyListeners();
  }

  /// 큐 내 아이템 순서 변경.
  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;
    await _service.moveQueueItem(oldIndex, newIndex);
    final newQueue = [..._queue];
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);
    _queue = newQueue;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
