import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/file_name_sanitizer.dart';

/// 파일 시스템 경로 관리 및 파일 조작을 담당하는 서비스.
///
/// 저장 경로 생성, 파일명 정제, 고유 경로 생성 등을 제공.
/// [DownloadProvider]·[SettingsProvider]에서 사용.
class FileService {
  /// Android 공용 다운로드 디렉토리 하위 앱 폴더 경로.
  static const _androidDownloadPath = '/storage/emulated/0/Download/MyMusicApp';

  /// 기본 저장 디렉토리 경로 반환. 존재하지 않으면 자동 생성.
  ///
  /// Android: [_androidDownloadPath] (파일 탐색기에서 접근 가능).
  /// iOS: 앱 Documents 디렉토리 (iTunes 파일 공유 가능).
  /// 외부 저장소 접근 실패 시 앱 내부 디렉토리로 fallback.
  Future<String> getDefaultSavePath() async {
    if (Platform.isIOS) {
      return _getDocumentsSavePath();
    }
    try {
      final downloadDir = Directory(_androidDownloadPath);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir.path;
    } catch (_) {
      return _getDocumentsSavePath();
    }
  }

  /// 앱 Documents/MyMusicApp 경로 반환. 미존재 시 생성.
  Future<String> _getDocumentsSavePath() async {
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

  /// 썸네일 저장 디렉토리 경로 반환. 미존재 시 자동 생성.
  Future<String> getThumbnailDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory('${appDir.path}/thumbnails');
    if (!thumbDir.existsSync()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir.path;
  }

  /// [url]에서 썸네일을 다운로드하여 [m4aFileName] 기준 로컬 경로에 저장.
  ///
  /// 저장 성공 시 로컬 파일 경로 반환, 실패 시 null.
  Future<String?> saveThumbnail(String url, String m4aFileName) async {
    try {
      final thumbDir = await getThumbnailDir();
      final baseName = m4aFileName.endsWith('.m4a')
          ? m4aFileName.substring(0, m4aFileName.length - 4)
          : m4aFileName;
      final localPath = '$thumbDir/$baseName.jpg';

      if (File(localPath).existsSync()) return localPath;

      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          await File(localPath).writeAsBytes(bytes);
          return localPath;
        }
        return null;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[FileService] Thumbnail save failed (StorageException): $e');
      return null;
    }
  }

  /// [m4aFileName] 기준 로컬 썸네일 경로 반환. 미존재 시 null.
  Future<String?> getLocalThumbnailPath(String m4aFileName) async {
    final thumbDir = await getThumbnailDir();
    final baseName = m4aFileName.endsWith('.m4a')
        ? m4aFileName.substring(0, m4aFileName.length - 4)
        : m4aFileName;
    final localPath = '$thumbDir/$baseName.jpg';
    return File(localPath).existsSync() ? localPath : null;
  }
}
