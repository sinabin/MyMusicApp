import 'package:flutter/foundation.dart';
import '../data/local_storage.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';

/// 앱 설정 상태를 관리하는 Provider.
///
/// [LocalStorage]·[AuthService]·[FileService]를 조합하여
/// [AppSettings]를 초기화·변경하고 UI에 변경 사항을 알림.
class SettingsProvider extends ChangeNotifier {
  final LocalStorage _localStorage;
  final AuthService _authService;
  final FileService _fileService;
  AppSettings _settings = const AppSettings();

  SettingsProvider({
    required LocalStorage localStorage,
    required AuthService authService,
    required FileService fileService,
  })  : _localStorage = localStorage,
        _authService = authService,
        _fileService = fileService;

  /// 현재 설정값 반환.
  AppSettings get settings => _settings;

  /// 저장소에서 설정값을 불러와 초기화.
  Future<void> init() async {
    final bitrate = await _localStorage.getAudioBitrate();
    var savePath = await _localStorage.getSavePath();
    savePath ??= await _fileService.getDefaultSavePath();
    final isLoggedIn = await _authService.isLoggedIn();
    final email = await _authService.loadEmail();

    _settings = AppSettings(
      savePath: savePath,
      audioBitrate: bitrate,
      isLoggedIn: isLoggedIn,
      userEmail: email,
    );
    notifyListeners();
  }

  /// 오디오 [bitrate] 변경 및 영속 저장.
  Future<void> setBitrate(int bitrate) async {
    _settings = _settings.copyWith(audioBitrate: bitrate);
    await _localStorage.setAudioBitrate(bitrate);
    notifyListeners();
  }

  /// 저장 경로 [path] 변경 및 영속 저장.
  Future<void> setSavePath(String path) async {
    _settings = _settings.copyWith(savePath: path);
    await _localStorage.setSavePath(path);
    notifyListeners();
  }

  /// 로그인 상태 [value] 및 [email] 갱신.
  Future<void> setLoggedIn(bool value, {String? email}) async {
    _settings = _settings.copyWith(isLoggedIn: value, userEmail: email);
    if (email != null) {
      await _authService.saveEmail(email);
    }
    notifyListeners();
  }

  /// 인증 정보 삭제 및 로그아웃 처리.
  Future<void> logout() async {
    await _authService.logout();
    _settings = _settings.copyWith(isLoggedIn: false, userEmail: null);
    notifyListeners();
  }
}
