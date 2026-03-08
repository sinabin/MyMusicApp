/// YouTube 영상의 메타데이터 모델.
///
/// [YouTubeService]에서 조회한 영상 정보를 담으며,
/// [VideoPreviewCard]에서 미리보기 표시에 사용.
class VideoInfo {
  /// YouTube 영상 고유 식별자.
  final String videoId;

  /// 영상 제목.
  final String title;

  /// 채널(업로더) 이름.
  final String channelName;

  /// 영상 재생 시간.
  final Duration duration;

  /// 썸네일 이미지 URL.
  final String thumbnailUrl;

  /// 오디오 스트림 바이트 크기. 미확인 시 null.
  final int? audioStreamSize;

  const VideoInfo({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.duration,
    required this.thumbnailUrl,
    this.audioStreamSize,
  });

  /// "H:MM:SS" 또는 "M:SS" 형식의 재생 시간 문자열 반환.
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
