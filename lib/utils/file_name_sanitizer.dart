/// 파일명에서 OS 금지 문자를 제거하고 안전한 이름을 생성하는 유틸리티.
///
/// [FileService]에서 다운로드 파일명 정제 시 사용.
class FileNameSanitizer {
  FileNameSanitizer._();

  /// 파일명에 사용할 수 없는 문자 패턴.
  static final _invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// [fileName]에서 금지 문자를 제거하고 [maxLength] 이내로 잘라 안전한 파일명 반환.
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

  /// [baseName]과 [extension]으로 중복되지 않는 고유 파일명 생성.
  ///
  /// [exists] 콜백으로 파일 존재 여부를 확인하며, 중복 시 숫자 접미사 추가.
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
