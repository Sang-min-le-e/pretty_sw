import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/big_routine.dart';
import '../domain/small_routine.dart';
import 'routine_repository.dart';

final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return LocalRoutineRepository(ref.watch(localStorageServiceProvider));
});

/// 특정 날짜(연/월/일)에 적용되는 빅루틴 목록. family의 파라미터로 항상
/// 시:분:초를 버린 DateTime(연,월,일)을 넘겨주기로 약속한다 (안 그러면 같은
/// 날짜인데 캐시 키가 달라져서 Provider가 매번 새로 계산해버린다).
final bigRoutinesForDateProvider =
    FutureProvider.family<List<BigRoutine>, DateTime>((ref, date) {
      final repository = ref.watch(routineRepositoryProvider);
      return repository.getBigRoutinesForDate(date);
    });

/// 대시보드의 "미션 진행률" 계산을 위해 전체 빅루틴을 가져오는 provider.
final allBigRoutinesProvider = FutureProvider<List<BigRoutine>>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return repository.getAllBigRoutines();
});

final routineActionsProvider = Provider((ref) => RoutineActions(ref));

class RoutineActions {
  RoutineActions(this._ref);
  final Ref _ref;
  static const _uuid = Uuid();

  Future<void> createBigRoutine({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime date,
    bool isRecurring = false,
    Set<int> recurringWeekdays = const {},
  }) async {
    final repository = _ref.read(routineRepositoryProvider);
    final routine = BigRoutine(
      id: _uuid.v4(),
      title: title,
      startTime: startTime,
      endTime: endTime,
      date: date,
      isRecurring: isRecurring,
      recurringWeekdays: recurringWeekdays,
      smallRoutines: const [],
    );
    await repository.saveBigRoutine(routine);
    _invalidateAffected(routine);
  }

  Future<void> deleteBigRoutine(BigRoutine routine) async {
    if (routine.isSent) return; // 전송된 루틴은 잠긴다 — 화면에서도 버튼을 숨기지만 여기서도 한 번 더 막아둔다.
    final repository = _ref.read(routineRepositoryProvider);
    await repository.deleteBigRoutine(routine.id);
    _invalidateAffected(routine);
  }

  /// "행동 추가" — 빅루틴 하나에 스몰루틴(=목업 UI 상 "행동")을 추가한다.
  Future<void> addSmallRoutine(BigRoutine routine, String title) async {
    if (routine.isSent) return;
    final nextOrder = routine.smallRoutines.length;
    final updated = routine.copyWith(
      smallRoutines: [
        ...routine.smallRoutines,
        SmallRoutine(id: _uuid.v4(), order: nextOrder, title: title),
      ],
    );
    await _ref.read(routineRepositoryProvider).saveBigRoutine(updated);
    _invalidateAffected(updated);
  }

  /// 체크박스 토글 — 전송(잠금) 여부와 상관없이 항상 허용한다. "수정 불가"는
  /// 제목/시간/행동 구성이 안 바뀐다는 뜻이지, 완료 체크까지 막는다는 뜻은 아니다
  /// (워치에서 실제로 미션을 완료하는 것과 대응되는 동작이라 오히려 항상 열려있어야 한다).
  Future<void> toggleSmallRoutineDone(BigRoutine routine, SmallRoutine target) async {
    final updated = routine.copyWith(
      smallRoutines: [
        for (final s in routine.smallRoutines)
          if (s.id == target.id) s.copyWith(isDone: !s.isDone) else s,
      ],
    );
    await _ref.read(routineRepositoryProvider).saveBigRoutine(updated);
    _invalidateAffected(updated);
  }

  Future<void> deleteSmallRoutine(BigRoutine routine, String smallId) async {
    if (routine.isSent) return;
    final remaining = routine.smallRoutines.where((s) => s.id != smallId).toList();
    final reordered = [for (var i = 0; i < remaining.length; i++) remaining[i].copyWith(order: i)];
    final updated = routine.copyWith(smallRoutines: reordered);
    await _ref.read(routineRepositoryProvider).saveBigRoutine(updated);
    _invalidateAffected(updated);
  }

  /// "전송하기" — 목업에 있던 "한 번 전송한 루틴은 수정할 수 없습니다" 확인창을 누른 뒤
  /// 호출된다. 그 날짜에 해당하는 빅루틴을 전부 한꺼번에 잠근다(하나씩이 아니라
  /// 하루 단위로 전송하는 UX였기 때문).
  Future<void> sendRoutinesForDate(DateTime date) async {
    final repository = _ref.read(routineRepositoryProvider);
    final routines = await repository.getBigRoutinesForDate(date);
    for (final routine in routines) {
      await repository.saveBigRoutine(routine.copyWith(isSent: true));
    }
    _ref.invalidate(allBigRoutinesProvider);
    _ref.invalidate(bigRoutinesForDateProvider(DateTime(date.year, date.month, date.day)));
  }

  /// 알려진 한계: 고정(반복) 루틴은 끝나는 날짜가 없어서, 이 루틴이 영향을 주는
  /// "모든" 미래 날짜의 캐시를 다 무효화할 수는 없다. 그래서 방금 만든/수정한
  /// 기준 날짜(routine.date)만 무효화한다 — 아직 화면에서 열어보지 않은 미래
  /// 날짜는 처음 열 때 어차피 Hive에서 새로 읽어오므로 문제가 안 되고, 이미 열어본
  /// 적 있는 다른 날짜 화면은 앱을 한 번 더 들어가야 최신 상태가 보일 수 있다.
  void _invalidateAffected(BigRoutine routine) {
    _ref.invalidate(allBigRoutinesProvider);
    _ref.invalidate(
      bigRoutinesForDateProvider(DateTime(routine.date.year, routine.date.month, routine.date.day)),
    );
  }
}
