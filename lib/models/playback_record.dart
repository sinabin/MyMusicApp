import 'package:hive/hive.dart';

part 'playback_record.g.dart';

/// 재생 기록 모델.
///
/// Hive에 영속 저장되며, [PlaybackHistoryDb]를 통해 관리.
/// 90일 경과 시 자동 정리.
@HiveType(typeId: 3)
class PlaybackRecord extends HiveObject {
  /// 재생된 YouTube 영상 ID.
  @HiveField(0)
  String videoId;

  /// 재생 일시.
  @HiveField(1)
  DateTime playedAt;

  /// 실제 재생된 시간(밀리초).
  @HiveField(2)
  int? durationPlayedMs;

  PlaybackRecord({
    required this.videoId,
    required this.playedAt,
    this.durationPlayedMs,
  });
}
