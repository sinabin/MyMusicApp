import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class LocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<int> getAudioBitrate() async {
    final p = await prefs;
    return p.getInt(AppConstants.settingsKeyBitrate) ?? AppConstants.defaultBitrate;
  }

  Future<void> setAudioBitrate(int bitrate) async {
    final p = await prefs;
    await p.setInt(AppConstants.settingsKeyBitrate, bitrate);
  }

  Future<String?> getSavePath() async {
    final p = await prefs;
    return p.getString(AppConstants.settingsKeySavePath);
  }

  Future<void> setSavePath(String path) async {
    final p = await prefs;
    await p.setString(AppConstants.settingsKeySavePath, path);
  }
}
