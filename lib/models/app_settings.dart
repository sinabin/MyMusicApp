import 'package:flutter/material.dart';

/// 앱 설정값을 담는 불변 모델.
///
/// [SettingsProvider]가 상태를 관리하며, [LocalStorage]를 통해 영속 저장.
class AppSettings {
  /// 오디오 파일 저장 경로.
  final String savePath;

  /// YouTube 로그인 여부.
  final bool isLoggedIn;

  /// 로그인된 Google 계정 이메일.
  final String? userEmail;

  /// 곡 탭 시 전체 재생 여부. true면 해당 곡부터 전체 재생, false면 단일 곡 재생.
  final bool playAllOnTap;

  /// 테마 모드 (system / light / dark).
  final ThemeMode themeMode;

  /// 프리미엄 구매 여부.
  final bool isPremium;

  const AppSettings({
    this.savePath = '',
    this.isLoggedIn = false,
    this.userEmail,
    this.playAllOnTap = true,
    this.themeMode = ThemeMode.dark,
    this.isPremium = false,
  });

  /// 지정된 필드만 변경한 새 [AppSettings] 인스턴스 반환.
  AppSettings copyWith({
    String? savePath,
    bool? isLoggedIn,
    String? userEmail,
    bool? playAllOnTap,
    ThemeMode? themeMode,
    bool? isPremium,
  }) {
    return AppSettings(
      savePath: savePath ?? this.savePath,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      playAllOnTap: playAllOnTap ?? this.playAllOnTap,
      themeMode: themeMode ?? this.themeMode,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
