class AppConstants {
  AppConstants._();

  static const String appName = 'MyMusicApp';
  static const String appVersion = '1.0.0';

  static const List<int> supportedBitrates = [128, 192, 256, 320];
  static const int defaultBitrate = 320;

  static const String hiveDownloadBox = 'download_history';

  static const String settingsKeyBitrate = 'audio_bitrate';
  static const String settingsKeySavePath = 'save_path';
}
