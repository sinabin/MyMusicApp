import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// YouTube 인증 정보(쿠키·이메일)의 안전한 저장·조회·삭제를 담당하는 서비스.
///
/// [FlutterSecureStorage]를 사용하며, [SettingsProvider]에서 로그인 상태 관리 시 참조.
class AuthService {
  static const _cookieKey = 'youtube_cookies';
  static const _emailKey = 'youtube_email';
  final _storage = const FlutterSecureStorage();

  /// [cookies]를 JSON 직렬화하여 보안 저장소에 저장.
  Future<void> saveCookies(Map<String, String> cookies) async {
    await _storage.write(key: _cookieKey, value: jsonEncode(cookies));
  }

  /// 보안 저장소에서 쿠키를 복원. 저장된 값이 없으면 null 반환.
  Future<Map<String, String>?> loadCookies() async {
    final data = await _storage.read(key: _cookieKey);
    if (data == null) return null;
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  /// 사용자 [email]을 보안 저장소에 저장.
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  /// 저장된 이메일 반환. 없으면 null.
  Future<String?> loadEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// 유효한 쿠키 존재 여부로 로그인 상태 판별.
  Future<bool> isLoggedIn() async {
    final cookies = await loadCookies();
    return cookies != null && cookies.isNotEmpty;
  }

  /// 저장된 쿠키와 이메일을 모두 삭제하여 로그아웃 처리.
  Future<void> logout() async {
    await _storage.delete(key: _cookieKey);
    await _storage.delete(key: _emailKey);
  }
}
