import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// SharedPreferences를 이용한 앱 설정 영속 저장소.
///
/// 저장 경로 등 경량 설정값을 관리.
/// [SettingsProvider]에서 설정 초기화 및 변경 시 사용.
class LocalStorage {
  SharedPreferences? _prefs;

  /// 지연 초기화되는 [SharedPreferences] 인스턴스 반환.
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 저장된 파일 저장 경로 반환. 미설정 시 null.
  Future<String?> getSavePath() async {
    final p = await prefs;
    return p.getString(AppConstants.settingsKeySavePath);
  }

  /// 파일 저장 [path] 설정값 저장.
  Future<void> setSavePath(String path) async {
    final p = await prefs;
    await p.setString(AppConstants.settingsKeySavePath, path);
  }
}
