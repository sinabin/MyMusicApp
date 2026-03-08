import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/file_name_sanitizer.dart';

/// 파일 시스템 경로 관리 및 파일 조작을 담당하는 서비스.
///
/// 저장 경로 생성, 파일명 정제, 고유 경로 생성 등을 제공.
/// [DownloadProvider]·[SettingsProvider]에서 사용.
class FileService {
  /// 기본 저장 디렉토리 경로 반환. 존재하지 않으면 자동 생성.
  Future<String> getDefaultSavePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/MyMusicApp');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir.path;
  }

  /// 임시 디렉토리 경로 반환.
  Future<String> getTempPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// [fileName]에서 OS 금지 문자를 제거한 안전한 파일명 반환.
  String sanitizeFileName(String fileName) {
    return FileNameSanitizer.sanitize(fileName);
  }

  /// [directory] 내에서 중복되지 않는 고유 파일 경로 생성.
  Future<String> getUniqueFilePath(String directory, String baseName, String extension) async {
    final safeName = sanitizeFileName(baseName);
    final fileName = FileNameSanitizer.makeUnique(
      safeName,
      extension,
      (name) => File('$directory/$name').existsSync(),
    );
    return '$directory/$fileName';
  }

  /// [path] 파일의 바이트 크기 반환.
  Future<int> getFileSize(String path) async {
    final file = File(path);
    return await file.length();
  }

  /// [path] 파일 존재 여부 반환.
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// [path] 파일이 존재하면 삭제.
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
