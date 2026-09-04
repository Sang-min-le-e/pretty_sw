import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/companion_character.dart';
import 'character_repository.dart';

final characterRepositoryProvider = Provider((ref) {
  return CharacterRepository(LocalStorageService());
});

final companionCharacterProvider = FutureProvider<CompanionCharacter>((ref) {
  return ref.watch(characterRepositoryProvider).getCharacter();
});

/// 스몰루틴을 완료 체크할 때(routine_providers의 toggleSmallRoutineDone과는 별개로)
/// 대시보드나 루틴 화면에서 "먹이 주기" 버튼을 눌렀을 때 호출한다.
/// 지금은 라우틴 완료 체크와 먹이주기를 분리해뒀는데, 이렇게 하면 "완료 체크는
/// 했지만 아직 워치에서 보상 연출을 확인 못 한 상태"처럼 두 이벤트가 시간차를
/// 두고 일어나는 실제 사용 흐름(워치 진동 -> 캐릭터 성장 연출)을 앱에서도
/// 비슷하게 흉내낼 수 있다.
class CharacterActions {
  CharacterActions(this._ref);
  final Ref _ref;

  Future<void> feed() async {
    final repo = _ref.read(characterRepositoryProvider);
    final current = await repo.getCharacter();
    await repo.save(current.feed());
    _ref.invalidate(companionCharacterProvider);
  }
}

final characterActionsProvider = Provider((ref) => CharacterActions(ref));
