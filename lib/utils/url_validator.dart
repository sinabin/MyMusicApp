/// YouTube URL 유효성 검증 및 영상 ID 추출 유틸리티.
///
/// 일반 URL, 단축 URL, Shorts, 모바일, YouTube Music 형식을 지원.
/// [UrlInputField]에서 입력값 검증에 사용.
class UrlValidator {
  UrlValidator._();

  /// 지원하는 YouTube URL 패턴 목록.
  static final _patterns = [
    RegExp(r'(?:https?://)?(?:www\.|m\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?(?:www\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?music\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
  ];

  /// [url]이 유효한 YouTube URL인지 판별.
  static bool isValid(String url) {
    return extractVideoId(url) != null;
  }

  /// [url]에서 11자리 YouTube 영상 ID를 추출. 유효하지 않으면 null 반환.
  static String? extractVideoId(String url) {
    final trimmed = url.trim();
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }
}
