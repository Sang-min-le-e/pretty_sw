import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';

abstract class OnboardingRepository {
  Future<bool> hasGuardianInfo();
  Future<void> saveGuardianInfo({required String name, required String relationship});
  Future<void> saveChildInfo({required String name, required DateTime birthDate});
}

/// Hive 기반 로컬 구현체. 이 계정에 보호자 정보가 저장돼 있는지로
/// "로그인 내역 없는 최초 로그인" 여부를 판단한다.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository(this._storage);

  static const _boxName = 'onboarding';
  static const _guardianInfoKey = 'guardian_info';
  static const _childInfoKey = 'child_info';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<bool> hasGuardianInfo() async {
    final box = await _box;
    return box.containsKey(_guardianInfoKey);
  }

  @override
  Future<void> saveGuardianInfo({required String name, required String relationship}) async {
    final box = await _box;
    await box.put(_guardianInfoKey, {'name': name, 'relationship': relationship});
  }

  @override
  Future<void> saveChildInfo({required String name, required DateTime birthDate}) async {
    final box = await _box;
    await box.put(_childInfoKey, {
      'name': name,
      'birthDate': birthDate.toIso8601String(),
    });
  }
}
