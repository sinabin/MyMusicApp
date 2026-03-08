import 'package:flutter/foundation.dart';
import '../data/local_storage.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../services/youtube_service.dart';

/// 앱 설정 상태를 관리하는 Provider.
///
/// [LocalStorage]·[AuthService]·[FileService]·[YouTubeService]를 조합하여
/// [AppSettings]를 초기화·변경하고 UI에 변경 사항을 알림.
class SettingsProvider extends ChangeNotifier {
  final LocalStorage _localStorage;
  final AuthService _authService;
  final FileService _fileService;
  final YouTubeService _youtubeService;
  AppSettings _settings = const AppSettings();

  SettingsProvider({
    required LocalStorage localStorage,
    required AuthService authService,
    required FileService fileService,
    required YouTubeService youtubeService,
  })  : _localStorage = localStorage,
        _authService = authService,
        _fileService = fileService,
        _youtubeService = youtubeService;

  /// 현재 설정값 반환.
  AppSettings get settings => _settings;

  /// 저장소에서 설정값을 불러와 초기화.
  Future<void> init() async {
    var savePath = await _localStorage.getSavePath();
    savePath ??= await _fileService.getDefaultSavePath();
    final isLoggedIn = await _authService.isLoggedIn();
    final email = await _authService.loadEmail();
    final playAllOnTap = await _localStorage.getPlayAllOnTap();

    _settings = AppSettings(
      savePath: savePath,
      isLoggedIn: isLoggedIn,
      userEmail: email,
      playAllOnTap: playAllOnTap,
    );
    notifyListeners();
  }

  /// 저장 경로 [path] 변경 및 영속 저장.
  Future<void> setSavePath(String path) async {
    if (_settings.savePath == path) return;
    _settings = _settings.copyWith(savePath: path);
    await _localStorage.setSavePath(path);
    notifyListeners();
  }

  /// 로그인 상태 [value] 및 [email] 갱신. YouTube 클라이언트 인증 상태도 반영.
  Future<void> setLoggedIn(bool value, {String? email}) async {
    if (_settings.isLoggedIn == value && _settings.userEmail == email) return;
    _settings = _settings.copyWith(isLoggedIn: value, userEmail: email);
    if (email != null) {
      await _authService.saveEmail(email);
    }
    await _youtubeService.refreshClient();
    notifyListeners();
  }

  /// 탭 재생 모드 [value] 변경 및 영속 저장.
  Future<void> setPlayAllOnTap(bool value) async {
    if (_settings.playAllOnTap == value) return;
    _settings = _settings.copyWith(playAllOnTap: value);
    await _localStorage.setPlayAllOnTap(value);
    notifyListeners();
  }

  /// 인증 정보 삭제 및 로그아웃 처리. YouTube 클라이언트 인증 상태도 반영.
  Future<void> logout() async {
    await _authService.logout();
    _settings = _settings.copyWith(isLoggedIn: false, userEmail: null);
    await _youtubeService.refreshClient();
    notifyListeners();
  }
}
