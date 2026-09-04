import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/child_profile.dart';
import '../domain/guardian_profile.dart';
import 'onboarding_repository.dart';

final onboardingRepositoryProvider = Provider((ref) {
  return OnboardingRepository(LocalStorageService());
});

/// 프로필 탭 상단의 "내 정보" 카드에 쓰인다.
final guardianProfileProvider = FutureProvider<GuardianProfile?>((ref) {
  return ref.watch(onboardingRepositoryProvider).getGuardianProfile();
});

/// 임시로 폼 입력값을 들고 있는 상태.
///
/// 온보딩은 "보호자 정보 화면 -> 자녀 정보 화면 -> 페어링 화면"처럼 여러 화면에
/// 걸쳐 하나의 흐름을 이루는데, 각 화면이 입력받은 값을 어딘가에 잠깐 들고 있다가
/// 마지막에 한 번에 저장하는 대신, 여기서는 "입력받는 즉시 Hive에 저장"하는
/// 방식을 택했다. 이렇게 하면 사용자가 앱을 중간에 껐다 켜도 이미 입력한
/// 단계까지는 다시 안 물어봐도 되기 때문이다(초기 설정을 끝까지 한 번에
/// 못 끝낼 수도 있는 사용자층이라는 점을 고려함).
class OnboardingActions {
  OnboardingActions(this._ref);
  final Ref _ref;

  Future<void> saveGuardian(GuardianProfile guardian) {
    return _ref.read(onboardingRepositoryProvider).saveGuardianProfile(guardian);
  }

  Future<void> saveChild(ChildProfile child) {
    return _ref.read(onboardingRepositoryProvider).saveChildProfile(child);
  }

  Future<void> completePairing() {
    return _ref.read(onboardingRepositoryProvider).markPairingComplete();
  }

  Future<void> logout() async {
    await _ref.read(onboardingRepositoryProvider).reset();
    _ref.invalidate(guardianProfileProvider);
  }
}

final onboardingActionsProvider = Provider((ref) => OnboardingActions(ref));
