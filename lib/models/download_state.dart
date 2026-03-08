enum DownloadPhase {
  idle,
  fetching,
  downloading,
  converting,
  completed,
  error,
}

class DownloadStatus {
  final DownloadPhase phase;
  final double progress;
  final String? statusText;
  final String? errorMessage;
  final int? downloadedBytes;
  final int? totalBytes;

  const DownloadStatus({
    this.phase = DownloadPhase.idle,
    this.progress = 0.0,
    this.statusText,
    this.errorMessage,
    this.downloadedBytes,
    this.totalBytes,
  });

  DownloadStatus copyWith({
    DownloadPhase? phase,
    double? progress,
    String? statusText,
    String? errorMessage,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    return DownloadStatus(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  bool get isActive =>
      phase == DownloadPhase.fetching ||
      phase == DownloadPhase.downloading ||
      phase == DownloadPhase.converting;
}
