class AppSettings {
  final String savePath;
  final int audioBitrate;
  final bool isLoggedIn;
  final String? userEmail;

  const AppSettings({
    this.savePath = '',
    this.audioBitrate = 320,
    this.isLoggedIn = false,
    this.userEmail,
  });

  AppSettings copyWith({
    String? savePath,
    int? audioBitrate,
    bool? isLoggedIn,
    String? userEmail,
  }) {
    return AppSettings(
      savePath: savePath ?? this.savePath,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
