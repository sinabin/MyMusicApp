import 'package:flutter/foundation.dart';
import '../data/local_storage.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';

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

  AppSettings get settings => _settings;

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

  Future<void> setBitrate(int bitrate) async {
    _settings = _settings.copyWith(audioBitrate: bitrate);
    await _localStorage.setAudioBitrate(bitrate);
    notifyListeners();
  }

  Future<void> setSavePath(String path) async {
    _settings = _settings.copyWith(savePath: path);
    await _localStorage.setSavePath(path);
    notifyListeners();
  }

  Future<void> setLoggedIn(bool value, {String? email}) async {
    _settings = _settings.copyWith(isLoggedIn: value, userEmail: email);
    if (email != null) {
      await _authService.saveEmail(email);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _settings = _settings.copyWith(isLoggedIn: false, userEmail: null);
    notifyListeners();
  }
}
