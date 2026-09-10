import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';

abstract class AuthSessionRepository {
  Future<String?> getAccessUuid();
  Future<void> saveAccessUuid(String uuid);
  Future<void> clearAccessUuid();
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
}
