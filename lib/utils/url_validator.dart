class UrlValidator {
  UrlValidator._();

  static final _patterns = [
    RegExp(r'(?:https?://)?(?:www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?(?:www\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?(?:m\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'(?:https?://)?music\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
  ];

  static bool isValid(String url) {
    return extractVideoId(url) != null;
  }

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
