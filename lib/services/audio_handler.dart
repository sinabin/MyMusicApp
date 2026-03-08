import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// [BaseAudioHandler] 구현체.
///
/// [just_audio]의 [AudioPlayer]를 래핑하여 백그라운드 재생 및
/// Android 알림 컨트롤을 제공. [AudioPlayerService]에서 사용.
class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist =
      ConcatenatingAudioSource(children: []);

  /// [AudioPlayer] 인스턴스 반환.
  AudioPlayer get player => _player;

  /// 재생 큐 [ConcatenatingAudioSource] 반환.
  ConcatenatingAudioSource get playlist => _playlist;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null &&
          queue.value.isNotEmpty &&
          index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  /// 오디오 소스 목록을 설정하고 큐 업데이트.
  Future<void> setAudioSource(
    List<MediaItem> items, {
    int initialIndex = 0,
  }) async {
    final audioSources = items
        .map((item) => AudioSource.file(item.id, tag: item))
        .toList();

    await _playlist.clear();
    await _playlist.addAll(audioSources);
    queue.add(items);

    await _player.setAudioSource(_playlist, initialIndex: initialIndex);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final newQueue = [...queue.value, mediaItem];
    queue.add(newQueue);
    await _playlist.add(AudioSource.file(mediaItem.id, tag: mediaItem));
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    final newQueue = [...queue.value]..removeAt(index);
    queue.add(newQueue);
    await _playlist.removeAt(index);
  }

  /// 큐 내 아이템 순서 변경.
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= queue.value.length) return;
    if (newIndex < 0 || newIndex >= queue.value.length) return;
    final newQueue = [...queue.value];
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);
    queue.add(newQueue);
    await _playlist.move(oldIndex, newIndex);
  }
}
