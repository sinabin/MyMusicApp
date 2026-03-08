import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
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

  Future<int> _getAndroidSdk() async {
    // Default to SDK 33+ behavior
    return 33;
  }
}
