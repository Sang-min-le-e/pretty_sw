import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/child_profile.dart';
import '../domain/guardian_profile.dart';

/// 초기 설정(온보딩) 진행 상태를 저장/조회하는 저장소.
///
/// Figma "1. 초기 설정" 흐름: 소셜 로그인 -> 보호자 정보 -> 자녀 정보 -> 페어링 ->
/// 완료되면 메인창(대시보드)으로 이동. 이 저장소는 그 흐름이 "어디까지 끝났는지"를
/// Hive에 저장해뒀다가, 앱을 다시 켰을 때 처음부터 다시 시키지 않기 위해 쓰인다.
///
/// Hive 박스 하나에 항목을 여러 개 두는 대신 'onboarding'이라는 박스에
/// 고정된 key('profile') 하나로 모든 정보를 몰아넣었다. 온보딩 정보는
/// "여러 개 중 하나를 골라 보는" 목록이 아니라 "앱 전체에 하나만 존재하는 설정값"이라
/// 리스트/목록 조회가 필요 없기 때문에, 굳이 여러 key로 쪼개지 않았다.
class OnboardingRepository {
  OnboardingRepository(this._storage);

  static const _boxName = 'onboarding';
  static const _profileKey = 'profile';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  Future<bool> isComplete() async {
    final box = await _box;
    final raw = box.get(_profileKey);
    return raw != null && raw['isPairingComplete'] == true;
  }

  Future<GuardianProfile?> getGuardianProfile() async {
    final raw = await _readProfile();
    if (raw == null) return null;
    return GuardianProfile.fromMap(Map<String, dynamic>.from(raw['guardian']));
  }

  Future<ChildProfile?> getChildProfile() async {
    final raw = await _readProfile();
    if (raw == null || raw['child'] == null) return null;
    return ChildProfile.fromMap(Map<String, dynamic>.from(raw['child']));
  }

  Future<void> saveGuardianProfile(GuardianProfile guardian) async {
    await _mergeProfile({'guardian': guardian.toMap()});
  }

  Future<void> saveChildProfile(ChildProfile child) async {
    await _mergeProfile({'child': child.toMap()});
  }

  Future<void> markPairingComplete() async {
    await _mergeProfile({'isPairingComplete': true});
  }

  Future<Map<dynamic, dynamic>?> _readProfile() async {
    final box = await _box;
    return box.get(_profileKey);
  }

  /// 기존에 저장된 값 위에 새 필드만 덮어써서 저장한다.
  /// (단계별로 하나씩 채워나가는 폼이라, 매번 전체를 다 다시 쓰지 않고
  /// "이번 단계에서 새로 얻은 값"만 합쳐주는 게 자연스럽다.)
  Future<void> _mergeProfile(Map<String, dynamic> patch) async {
    final box = await _box;
    final existing = Map<String, dynamic>.from(
      box.get(_profileKey) ?? <String, dynamic>{},
    );
    existing.addAll(patch);
    await box.put(_profileKey, existing);
  }
}
