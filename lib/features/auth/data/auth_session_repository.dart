import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';

abstract class AuthSessionRepository {
  Future<String?> getAccessUuid();
  Future<void> saveAccessUuid(String uuid);
  Future<void> clearAccessUuid();

  /// 이 기기에서 마지막으로 로그인한 시각. 서버가 로그인 기록을 주지 않아서
  /// "로그인 기록" 화면은 이 값 하나만 보여준다. 로그인한 적이 없으면 `null`.
  Future<DateTime?> getLastLoginAt();
  Future<void> saveLastLoginAt(DateTime time);
}

/// Hive 기반 로컬 구현체. `docs/API.md` 1-1 — 백엔드는 JWT를 쓰지 않고
/// 로그인 때 발급한 임의의 UUID(`X-Access-Uuid`)로만 누구인지 알아낸다.
/// 그 값을 기기에 들고 있는 게 이 저장소의 역할이다. 만료가 없어서
/// 로그아웃(`clearAccessUuid`)이 유일하게 이 값을 무효로 만드는 방법이다
/// (서버 쪽에서도 로그아웃 시 `USERS.access_uuid`를 비운다).
class LocalAuthSessionRepository implements AuthSessionRepository {
  LocalAuthSessionRepository(this._storage);

  static const _boxName = 'auth';
  static const _accessUuidKey = 'access_uuid';
  static const _lastLoginAtKey = 'last_login_at';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<String?> getAccessUuid() async {
    final box = await _box;
    return box.get(_accessUuidKey)?['value'] as String?;
  }

  @override
  Future<void> saveAccessUuid(String uuid) async {
    final box = await _box;
    await box.put(_accessUuidKey, {'value': uuid});
  }

  @override
  Future<void> clearAccessUuid() async {
    final box = await _box;
    await box.delete(_accessUuidKey);
  }

  @override
  Future<DateTime?> getLastLoginAt() async {
    final box = await _box;
    final raw = box.get(_lastLoginAtKey)?['value'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> saveLastLoginAt(DateTime time) async {
    final box = await _box;
    await box.put(_lastLoginAtKey, {'value': time.toIso8601String()});
  }
}
