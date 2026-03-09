import 'package:flutter/material.dart';
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

  /// 탭 재생 모드 반환. 미설정 시 true (전체 재생).
  Future<bool> getPlayAllOnTap() async {
    final p = await prefs;
    return p.getBool(AppConstants.settingsKeyPlayAllOnTap) ?? true;
  }

  /// 탭 재생 모드 [value] 저장.
  Future<void> setPlayAllOnTap(bool value) async {
    final p = await prefs;
    await p.setBool(AppConstants.settingsKeyPlayAllOnTap, value);
  }

  /// 다운로드 기록 숨김 기준 타임스탬프 반환. 미설정 시 null.
  Future<int?> getHistoryClearedAt() async {
    final p = await prefs;
    return p.getInt(AppConstants.settingsKeyHistoryClearedAt);
  }

  /// 다운로드 기록 숨김 기준 타임스탬프 저장 (밀리초).
  Future<void> setHistoryClearedAt(int millis) async {
    final p = await prefs;
    await p.setInt(AppConstants.settingsKeyHistoryClearedAt, millis);
  }

  /// 저장된 테마 모드 반환. 미설정 시 [ThemeMode.dark].
  Future<ThemeMode> getThemeMode() async {
    final p = await prefs;
    final index = p.getInt(AppConstants.settingsKeyThemeMode) ?? 2;
    return ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
  }

  /// 테마 모드 [mode] 저장.
  Future<void> setThemeMode(ThemeMode mode) async {
    final p = await prefs;
    await p.setInt(AppConstants.settingsKeyThemeMode, mode.index);
  }
}
