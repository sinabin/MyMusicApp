/// 앱 전역에서 사용하는 상수 정의.
class AppConstants {
  AppConstants._();

  /// 앱 표시 이름.
  static const String appName = 'MyMusicApp';

  /// 앱 버전.
  static const String appVersion = '1.0.0';

  /// 지원하는 오디오 비트레이트 목록(kbps).
  static const List<int> supportedBitrates = [128, 192, 256, 320];

  /// 기본 오디오 비트레이트(kbps).
  static const int defaultBitrate = 320;

  /// Hive 다운로드 기록 Box 이름.
  static const String hiveDownloadBox = 'download_history';

  /// SharedPreferences 비트레이트 저장 키.
  static const String settingsKeyBitrate = 'audio_bitrate';

  /// SharedPreferences 저장 경로 키.
  static const String settingsKeySavePath = 'save_path';
}
