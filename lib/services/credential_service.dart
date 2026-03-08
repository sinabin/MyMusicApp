import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 키-값 쌍을 보안 저장소에 저장·조회·삭제하는 범용 자격 증명 서비스.
///
/// [FlutterSecureStorage]를 래핑하여 간결한 인터페이스 제공.
class CredentialService {
  final _storage = const FlutterSecureStorage();

  /// [key]에 [value]를 저장.
  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// [key]에 해당하는 값 반환. 없으면 null.
  Future<String?> load(String key) async {
    return await _storage.read(key: key);
  }

  /// [key]에 해당하는 항목 삭제.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// 저장소의 모든 항목 일괄 삭제.
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
