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

  const AppSettings({
    this.savePath = '',
    this.isLoggedIn = false,
    this.userEmail,
  });

  /// 지정된 필드만 변경한 새 [AppSettings] 인스턴스 반환.
  AppSettings copyWith({
    String? savePath,
    bool? isLoggedIn,
    String? userEmail,
  }) {
    return AppSettings(
      savePath: savePath ?? this.savePath,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
