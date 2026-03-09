/// 앱 전역 예외 계층.
///
/// 모든 서비스·프로바이더에서 사용하는 타입화된 예외 클래스.
/// [userMessage]는 사용자에게 표시할 안내 문구, [message]는 디버그용 상세 메시지.
sealed class AppException implements Exception {
  /// 디버그용 상세 메시지.
  final String message;

  /// 사용자에게 표시할 안내 문구.
  final String userMessage;

  /// 원인 예외 (래핑 시 사용).
  final Object? cause;

  const AppException({
    required this.message,
    required this.userMessage,
    this.cause,
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// 네트워크 연결 실패 예외.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error',
    super.userMessage = 'Network connection failed',
    super.cause,
  });
}

/// YouTube 오디오 스트림을 찾을 수 없는 예외.
class StreamNotFoundException extends AppException {
  /// 조회 실패한 영상 ID.
  final String videoId;

  StreamNotFoundException({
    required this.videoId,
    super.cause,
  }) : super(
          message: 'No audio streams available for videoId=$videoId',
          userMessage: 'Audio stream not available',
        );
}

/// 검색 실패 예외.
class SearchException extends AppException {
  const SearchException({
    super.message = 'Search failed',
    super.userMessage = 'Search failed',
    super.cause,
  });
}

/// 다운로드 실패 예외.
class DownloadException extends AppException {
  const DownloadException({
    super.message = 'Download failed',
    super.userMessage = 'Download failed',
    super.cause,
  });
}

/// 파일 시스템·저장 공간 관련 예외.
class StorageException extends AppException {
  const StorageException({
    super.message = 'Storage error',
    super.userMessage = 'Storage access failed',
    super.cause,
  });
}

/// 스트리밍 재생 실패 예외.
class StreamingException extends AppException {
  const StreamingException({
    super.message = 'Streaming failed',
    super.userMessage = 'Streaming failed',
    super.cause,
  });
}
