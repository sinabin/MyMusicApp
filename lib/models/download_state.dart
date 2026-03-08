/// 다운로드 작업의 진행 단계.
enum DownloadPhase {
  /// 대기 상태.
  idle,

  /// 오디오 스트림 메타데이터 조회 중.
  fetching,

  /// 오디오 스트림 다운로드 중.
  downloading,

  /// FFmpeg를 이용한 MP3 변환 중.
  converting,

  /// 다운로드 및 변환 완료.
  completed,

  /// 에러 발생.
  error,
}

/// 다운로드 작업의 현재 상태를 나타내는 불변 모델.
///
/// [DownloadProvider]가 상태를 관리하며, [DownloadButton]·[ProgressIndicatorBar]에서 UI 반영.
class DownloadStatus {
  /// 현재 진행 단계.
  final DownloadPhase phase;

  /// 0.0~1.0 범위의 진행률.
  final double progress;

  /// UI에 표시할 상태 메시지.
  final String? statusText;

  /// 에러 발생 시 메시지.
  final String? errorMessage;

  /// 현재까지 다운로드된 바이트 수.
  final int? downloadedBytes;

  /// 전체 파일 바이트 수.
  final int? totalBytes;

  const DownloadStatus({
    this.phase = DownloadPhase.idle,
    this.progress = 0.0,
    this.statusText,
    this.errorMessage,
    this.downloadedBytes,
    this.totalBytes,
  });

  /// 지정된 필드만 변경한 새 [DownloadStatus] 인스턴스 반환.
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

  /// 다운로드가 진행 중인지 여부.
  bool get isActive =>
      phase == DownloadPhase.fetching ||
      phase == DownloadPhase.downloading ||
      phase == DownloadPhase.converting;
}
