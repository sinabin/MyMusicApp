import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/file_name_sanitizer.dart';

class FileService {
  Future<String> getDefaultSavePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/MyMusicApp');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir.path;
  }

  Future<String> getTempPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  String sanitizeFileName(String fileName) {
    return FileNameSanitizer.sanitize(fileName);
  }

  Future<String> getUniqueFilePath(String directory, String baseName, String extension) async {
    final safeName = sanitizeFileName(baseName);
    final fileName = FileNameSanitizer.makeUnique(
      safeName,
      extension,
      (name) => File('$directory/$name').existsSync(),
    );
    return '$directory/$fileName';
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);
    return await file.length();
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
