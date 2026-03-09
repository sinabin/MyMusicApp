/// 앱 전역에서 사용하는 상수 정의.
class AppConstants {
  AppConstants._();

  /// 앱 표시 이름.
  static const String appName = 'MyMusicApp';

  /// 앱 버전.
  static const String appVersion = '1.0.0';

  /// Hive 다운로드 기록 Box 이름.
  static const String hiveDownloadBox = 'download_history';

  /// SharedPreferences 저장 경로 키.
  static const String settingsKeySavePath = 'save_path';

  /// Hive dismiss 기록 Box 이름.
  static const String hiveDismissedBox = 'dismissed_recommendations';

  /// SharedPreferences 탭 재생 모드 키.
  static const String settingsKeyPlayAllOnTap = 'play_all_on_tap';

  /// SharedPreferences 다운로드 기록 숨김 기준 타임스탬프 키.
  static const String settingsKeyHistoryClearedAt = 'history_cleared_at';

  /// SharedPreferences 테마 모드 키 (0=system, 1=light, 2=dark).
  static const String settingsKeyThemeMode = 'theme_mode';

  /// Hive 플레이리스트 Box 이름.
  static const String hivePlaylistBox = 'playlists';

  /// Hive 재생 기록 Box 이름.
  static const String hivePlaybackBox = 'playback_history';

  /// SharedPreferences 프리미엄 상태 키.
  static const String settingsKeyIsPremium = 'is_premium';

  /// Google Play IAP 프리미엄 상품 ID.
  static const String premiumProductId = 'premium_unlock';

  /// Hive 가사 캐시 Box 이름.
  static const String hiveLyricsBox = 'lyrics_cache';
}
