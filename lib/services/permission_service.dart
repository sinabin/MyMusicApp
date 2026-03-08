import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// 런타임 권한 요청 및 상태 확인 서비스.
///
/// Android SDK 버전에 따라 적절한 권한(storage/audio)을 요청.
/// iOS는 앱 문서 디렉토리에 별도 권한이 불필요하므로 항상 true 반환.
class PermissionService {
  /// 저장소 접근 권한을 요청하고 허용 여부 반환.
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdk();
      if (sdkInt >= 33) {
        final status = await Permission.audio.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    // iOS doesn't need explicit storage permission for app documents
    return true;
  }

  /// 현재 저장소 접근 권한 보유 여부 반환.
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdk();
      if (sdkInt >= 33) {
        return await Permission.audio.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  /// Android SDK 버전 반환. 기본값 33 이상으로 처리.
  Future<int> _getAndroidSdk() async {
    // Default to SDK 33+ behavior
    return 33;
  }
}
