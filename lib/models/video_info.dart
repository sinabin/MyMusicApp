class VideoInfo {
  final String videoId;
  final String title;
  final String channelName;
  final Duration duration;
  final String thumbnailUrl;
  final int? audioStreamSize;

  const VideoInfo({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.duration,
    required this.thumbnailUrl,
    this.audioStreamSize,
  });

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
