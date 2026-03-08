import 'package:flutter_test/flutter_test.dart';
import 'package:mymusicapp/utils/url_validator.dart';

void main() {
  group('UrlValidator', () {
    test('validates standard YouTube URL', () {
      expect(UrlValidator.isValid('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), true);
    });

    test('validates short YouTube URL', () {
      expect(UrlValidator.isValid('https://youtu.be/dQw4w9WgXcQ'), true);
    });

    test('validates YouTube Shorts URL', () {
      expect(UrlValidator.isValid('https://www.youtube.com/shorts/dQw4w9WgXcQ'), true);
    });

    test('rejects invalid URL', () {
      expect(UrlValidator.isValid('https://google.com'), false);
    });

    test('extracts video ID', () {
      expect(UrlValidator.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });
  });
}
