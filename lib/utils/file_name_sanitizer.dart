class FileNameSanitizer {
  FileNameSanitizer._();

  static final _invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  static String sanitize(String fileName, {int maxLength = 200}) {
    var safe = fileName.replaceAll(_invalidChars, '_');
    safe = safe.replaceAll('%', 'percent');
    safe = safe.trim();

    // Remove trailing dots and spaces (Windows limitation)
    safe = safe.replaceAll(RegExp(r'[.\s]+$'), '');

    if (safe.isEmpty) {
      safe = 'download';
    }

    if (safe.length > maxLength) {
      safe = safe.substring(0, maxLength);
    }

    return safe;
  }

  static String makeUnique(String baseName, String extension, bool Function(String) exists) {
    var fileName = '$baseName$extension';
    if (!exists(fileName)) return fileName;

    var counter = 1;
    do {
      fileName = '${baseName}_$counter$extension';
      counter++;
    } while (exists(fileName));

    return fileName;
  }
}
