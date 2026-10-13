import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 기기에 마지막으로 알려 준 와이파이(이름 + 비밀번호).
///
/// iOS는 앱이 "지금 붙어 있는 와이파이의 비밀번호"를 읽을 방법을 주지 않는다
/// (이름도 위치 권한·특수 entitlement이 있어야 한다). 그래서 "기기 추가하기"에서
/// 사용자가 입력해 BLE로 기기에 넘긴 값을 키체인(암호화 저장소)에 남겨 두고,
/// "연결된 기기" 화면이 그걸 보여준다.
class WifiCredentials {
  const WifiCredentials({required this.ssid, required this.password});

  final String ssid;
  final String password;
}

class WifiCredentialsStore {
  WifiCredentialsStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _ssidKey = 'wifi_ssid';
  static const _passwordKey = 'wifi_password';

  Future<WifiCredentials?> read() async {
    try {
      final ssid = await _storage.read(key: _ssidKey);
      if (ssid == null || ssid.isEmpty) return null;
      final password = await _storage.read(key: _passwordKey) ?? '';
      return WifiCredentials(ssid: ssid, password: password);
    } catch (_) {
      return null; // 키체인을 못 읽어도 화면은 "없음"으로 그린다.
    }
  }

  Future<void> save(WifiCredentials credentials) async {
    await _storage.write(key: _ssidKey, value: credentials.ssid);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _ssidKey);
    await _storage.delete(key: _passwordKey);
  }
}

final wifiCredentialsStoreProvider = Provider((ref) => WifiCredentialsStore());

/// "연결된 기기" 화면이 보여 줄 와이파이 정보. 저장된 게 없으면 `null`.
final wifiCredentialsProvider = FutureProvider<WifiCredentials?>((ref) {
  return ref.watch(wifiCredentialsStoreProvider).read();
});
