import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/download_item.dart';
import 'audio_handler.dart';

/// [MyAudioHandler]를 래핑하여 재생 기능을 제공하는 서비스.
///
/// 파일 존재 여부 검증 후 재생하며, 스트림을 통해 재생 상태 노출.
/// [PlayerProvider]에서 사용.
class AudioPlayerService {
  final MyAudioHandler _handler;

  AudioPlayerService(this._handler);

  /// [AudioPlayer] 상태 스트림.
  Stream<PlayerState> get playerStateStream =>
      _handler.player.playerStateStream;

  /// 현재 재생 위치 스트림.
  Stream<Duration> get positionStream => _handler.player.positionStream;

  /// 곡 전체 길이 스트림.
  Stream<Duration?> get durationStream => _handler.player.durationStream;

  /// 현재 재생 인덱스 스트림.
  Stream<int?> get currentIndexStream => _handler.player.currentIndexStream;

  /// 시퀀스 상태 스트림.
  Stream<SequenceState?> get sequenceStateStream =>
      _handler.player.sequenceStateStream;

  /// 루프 모드 스트림.
  Stream<LoopMode> get loopModeStream => _handler.player.loopModeStream;

  /// 셔플 모드 스트림.
  Stream<bool> get shuffleModeEnabledStream =>
      _handler.player.shuffleModeEnabledStream;

  /// 현재 재생 여부.
  bool get playing => _handler.player.playing;

  /// 현재 재생 위치.
  Duration get position => _handler.player.position;

  /// 곡 전체 길이.
  Duration? get duration => _handler.player.duration;

  /// 재생 시작.
  Future<void> play() => _handler.play();

  /// 일시정지.
  Future<void> pause() => _handler.pause();

  /// 정지 및 리소스 해제.
  Future<void> stop() => _handler.stop();

  /// [position]으로 탐색.
  Future<void> seek(Duration position) => _handler.seek(position);

  /// 다음 곡으로 이동.
  Future<void> seekToNext() => _handler.skipToNext();

  /// 이전 곡으로 이동.
  Future<void> seekToPrevious() => _handler.skipToPrevious();

  /// 큐 내 [index] 위치의 곡으로 이동.
  Future<void> seekToIndex(int index) async {
    await _handler.skipToQueueItem(index);
    await _handler.play();
  }

  /// [items] 목록을 큐로 설정하고 [initialIndex]부터 재생.
  ///
  /// 파일 미존재 항목은 제외. 유효 항목이 없으면 빈 리스트 반환.
  Future<List<DownloadItem>> setQueue(
    List<DownloadItem> items, {
    int initialIndex = 0,
  }) async {
    final validItems =
        items.where((item) => File(item.filePath).existsSync()).toList();
    if (validItems.isEmpty) return [];

    var adjustedIndex = 0;
    if (initialIndex > 0 && initialIndex < items.length) {
      final targetItem = items[initialIndex];
      adjustedIndex = validItems.indexOf(targetItem);
      if (adjustedIndex < 0) adjustedIndex = 0;
    }

    final mediaItems = validItems.map(_toMediaItem).toList();
    await _handler.setAudioSource(mediaItems, initialIndex: adjustedIndex);
    await _handler.play();
    return validItems;
  }

  /// 큐에 단일 곡 추가.
  Future<void> addToQueue(DownloadItem item) async {
    if (!File(item.filePath).existsSync()) return;
    await _handler.addQueueItem(_toMediaItem(item));
  }

  /// 큐에서 [index] 위치의 곡 제거.
  Future<void> removeFromQueue(int index) => _handler.removeQueueItemAt(index);

  /// 큐 내 아이템 순서 변경.
  Future<void> moveQueueItem(int oldIndex, int newIndex) =>
      _handler.moveQueueItem(oldIndex, newIndex);

  /// 셔플 모드 설정.
  Future<void> setShuffleMode(bool enabled) =>
      _handler.player.setShuffleModeEnabled(enabled);

  /// 루프 모드 설정.
  Future<void> setLoopMode(LoopMode mode) => _handler.player.setLoopMode(mode);

  /// [DownloadItem]을 [MediaItem]으로 변환.
  MediaItem _toMediaItem(DownloadItem item) {
    final title = item.fileName.endsWith('.m4a')
        ? item.fileName.substring(0, item.fileName.length - 4)
        : item.fileName;
    return MediaItem(
      id: item.filePath,
      title: title,
      artist: item.artistName ?? item.channelName ?? '',
      artUri: item.thumbnailUrl != null ? Uri.parse(item.thumbnailUrl!) : null,
      duration: item.duration,
    );
  }

  /// 리소스 해제.
  void dispose() {
    _handler.player.dispose();
  }
}
