import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/big_routine.dart';
import '../domain/small_routine.dart';
import 'routine_repository.dart';

/// Riverpod 학습 포인트: 이 파일에는 3가지 종류의 Provider가 나온다.
///
/// 1) `Provider` — 값을 "만들기만" 하고 값 자체는 안 바뀐다. 여기서는
///    LocalStorageService, RoutineRepository처럼 앱 전체에서 하나만 있으면 되는
///    객체(싱글턴 비슷한 것)를 만드는 데 쓴다.
/// 2) `FutureProvider.family` — 비동기로 데이터를 읽어오는데, "어떤 날짜의 루틴이냐"처럼
///    파라미터(family)가 필요할 때 쓴다. 위젯에서 `ref.watch(bigRoutinesForDateProvider(date))`
///    하면 자동으로 로딩/에러/데이터 상태(AsyncValue)를 다 관리해준다.
/// 3) 쓰기(등록/수정/삭제) 동작은 별도의 "쓰기 전용" Provider를 만들지 않고,
///    아래 [RoutineActions] 클래스에 모아뒀다. Riverpod 3에서는 이런 식으로
///    ref를 받는 헬퍼 객체를 Provider로 노출해서 위젯이 `ref.read(routineActionsProvider).save(...)`
///    형태로 호출하게 하는 패턴이 흔하다. 그 다음 `ref.invalidate(...)`로 관련
///    FutureProvider를 무효화하면, 그 provider를 watch하고 있는 화면이 자동으로 다시 그려진다.

final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return LocalRoutineRepository(ref.watch(localStorageServiceProvider));
});

/// 특정 날짜(연/월/일)에 적용되는 빅루틴 목록.
/// family의 파라미터로 DateTime을 그대로 쓰면 시:분:초까지 달라서 캐시가 안 맞는
/// 경우가 생길 수 있어서, 항상 날짜만 있는 DateTime(연,월,일)을 넘겨주기로 약속한다.
final bigRoutinesForDateProvider =
    FutureProvider.family<List<BigRoutine>, DateTime>((ref, date) {
      final repository = ref.watch(routineRepositoryProvider);
      return repository.getBigRoutinesForDate(date);
    });

/// 대시보드의 "이번주/어제 미션 이행률" 계산을 위해 전체 빅루틴을 가져오는 provider.
final allBigRoutinesProvider = FutureProvider<List<BigRoutine>>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return repository.getAllBigRoutines();
});

final routineActionsProvider = Provider((ref) => RoutineActions(ref));

class RoutineActions {
  RoutineActions(this._ref);
  final Ref _ref;
  static const _uuid = Uuid();

  /// 날짜 하나(또는 연속 날짜 범위)에 적용될 새 빅루틴을 만든다.
  /// 스몰루틴은 처음엔 비어있는 채로 시작하고, 등록 화면에서 하나씩 추가한다.
  Future<void> createBigRoutine({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime startDate,
    required DateTime endDate,
    bool isFixedDefault = false,
  }) async {
    final repository = _ref.read(routineRepositoryProvider);
    final routine = BigRoutine(
      id: _uuid.v4(),
      title: title,
      startTime: startTime,
      endTime: endTime,
      startDate: startDate,
      endDate: endDate,
      isFixedDefault: isFixedDefault,
      smallRoutines: const [],
    );
    await repository.saveBigRoutine(routine);
    _invalidateAffected(routine);
  }

  Future<void> deleteBigRoutine(BigRoutine routine) async {
    final repository = _ref.read(routineRepositoryProvider);
    await repository.deleteBigRoutine(routine.id);
    _invalidateAffected(routine);
  }

  /// 빅루틴 하나에 스몰루틴을 추가한다. (팝업에서 "+" 눌렀을 때)
  Future<void> addSmallRoutine(BigRoutine routine, String title) async {
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

  /// 스몰루틴 체크박스를 눌러 완료 처리 — 이 값이 대시보드의 미션 이행률 계산에 쓰인다.
  Future<void> toggleSmallRoutineDone(
    BigRoutine routine,
    SmallRoutine target,
  ) async {
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
    final remaining = routine.smallRoutines
        .where((s) => s.id != smallId)
        .toList();
    // 하나를 지운 뒤에는 순서(order) 값에 빈 자리가 생기지 않도록 다시 매긴다.
    final reordered = [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(order: i),
    ];
    final updated = routine.copyWith(smallRoutines: reordered);
    await _ref.read(routineRepositoryProvider).saveBigRoutine(updated);
    _invalidateAffected(updated);
  }

  /// 빅루틴 하나가 바뀌면, 그 빅루틴이 걸쳐 있는 모든 날짜의 캐시와
  /// 대시보드용 전체 목록 캐시를 함께 무효화해야 화면이 최신 상태로 갱신된다.
  void _invalidateAffected(BigRoutine routine) {
    _ref.invalidate(allBigRoutinesProvider);
    for (
      var day = routine.startDate;
      !day.isAfter(routine.endDate);
      day = day.add(const Duration(days: 1))
    ) {
      _ref.invalidate(bigRoutinesForDateProvider(DateTime(day.year, day.month, day.day)));
    }
  }
}
