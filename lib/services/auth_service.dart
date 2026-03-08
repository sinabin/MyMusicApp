import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _cookieKey = 'youtube_cookies';
  static const _emailKey = 'youtube_email';
  final _storage = const FlutterSecureStorage();

  Future<void> saveCookies(Map<String, String> cookies) async {
    await _storage.write(key: _cookieKey, value: jsonEncode(cookies));
  }

  Future<Map<String, String>?> loadCookies() async {
    final data = await _storage.read(key: _cookieKey);
    if (data == null) return null;
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> loadEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<bool> isLoggedIn() async {
    final cookies = await loadCookies();
    return cookies != null && cookies.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: _cookieKey);
    await _storage.delete(key: _emailKey);
  }
}
