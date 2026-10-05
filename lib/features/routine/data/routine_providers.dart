import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../auth/data/auth_providers.dart';
import '../../children/data/child_providers.dart';
import '../domain/new_routine.dart';
import '../domain/routine.dart';
import 'routine_repository.dart';

/// 템플릿 provider들이 같이 쓰는 Hive 도구(템플릿은 아직 로컬에 저장한다).
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return ApiRoutineRepository(ref.watch(apiClientProvider));
});

/// 달력 조회 한 번을 가리키는 키: 어느 자녀의, 어느 기간(둘 다 날짜만 의미).
/// 레코드라서 값이 같으면 같은 키로 취급되어, 같은 조회가 캐시를 공유한다.
typedef CalendarQuery = ({int childId, DateTime from, DateTime to});

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [day]가 속한 달 전체(1일~말일)를 조회하는 키. 서버가 한 번에 한 달을
/// 주도록(`calendar` 범위 상한 31일 제안) 달 단위로 자른다.
CalendarQuery monthQuery(int childId, DateTime day) {
  return (
    childId: childId,
    from: DateTime(day.year, day.month, 1),
    to: DateTime(day.year, day.month + 1, 0), // 0일 = 전달 말일
  );
}

/// 기간 안의 루틴(서버 `calendar`)을 통째로 읽는다. **`autoDispose`**라서 이
/// 데이터를 보는 화면이 모두 사라지면 캐시가 버려지고, 화면에 다시 들어오면
/// 서버에서 새로 받아온다 — 아이가 기기에서 할 일을 완료하면 서버에만 반영되고
/// 앱은 알 수 없어서, 화면에 들어올 때마다 다시 받는 것이 서버 문서의 권고다.
final routineCalendarProvider =
    FutureProvider.autoDispose.family<List<Routine>, CalendarQuery>((ref, query) {
  return ref.watch(routineRepositoryProvider).getCalendar(
        childId: query.childId,
        from: query.from,
        to: query.to,
      );
});

/// 지금 보는 자녀의, [date]가 속한 달 루틴 목록. 자녀가 아직 없거나(로딩
/// 중·미등록) 달력이 로딩 중이면 빈 목록으로 취급한다 — 화면이 로딩 스피너
/// 없이 "루틴 없음"으로 보이다가 데이터가 오면 자동으로 다시 그려진다.
final _currentMonthRoutinesProvider =
    Provider.autoDispose.family<List<Routine>, DateTime>((ref, anyDayInMonth) {
  final child = ref.watch(currentChildProvider);
  if (child == null) return const [];
  final query = monthQuery(child.childId, anyDayInMonth);
  return ref.watch(routineCalendarProvider(query)).value ?? const [];
});

/// 달력에서 고른 날짜(연/월/일)의 루틴만 걸러서 시작 시각 순으로 돌려준다.
/// `.family`라서 `ref.watch(routinesForDateProvider(날짜))`처럼 날짜를 넘긴다.
final routinesForDateProvider =
    Provider.autoDispose.family<List<Routine>, DateTime>((ref, date) {
  final day = _dateOnly(date);
  final sameDay = ref
      .watch(_currentMonthRoutinesProvider(day))
      .where((r) => r.date == day)
      .toList();
  sameDay.sort((a, b) => a.startTime.compareTo(b.startTime));
  return sameDay;
});

/// [month]가 속한 한 달 동안 "일(day) → 그날 루틴 개수" 맵. 달력 칸 아래의 작은
/// 회색 배지(예: 8일 아래 "3")가 쓴다. 루틴이 없는 날은 키 자체가 없다.
final routineCountsByDayProvider =
    Provider.autoDispose.family<Map<int, int>, DateTime>((ref, month) {
  final counts = <int, int>{};
  for (final routine in ref.watch(_currentMonthRoutinesProvider(month))) {
    counts[routine.date.day] = (counts[routine.date.day] ?? 0) + 1;
  }
  return counts;
});

/// 루틴을 서버에 만드는 동작. 만든 뒤 달력 캐시를 무효화(invalidate)해서, 그
/// 데이터를 보는 모든 화면(달력, 오늘 할 일, 홈 카드)이 새 목록을 다시 받게 한다.
final routineActionsProvider = Provider((ref) => RoutineActions(ref));

class RoutineActions {
  RoutineActions(this._ref);

  final Ref _ref;

  /// [routine]을 지금 보는 자녀에게 만들고, 서버가 만든 개수를 돌려준다.
  Future<int> createRoutine(NewRoutine routine) async {
    final child = _ref.read(currentChildProvider);
    if (child == null) {
      throw const ApiException(
        code: 'NO_CHILD',
        message: '등록된 자녀가 없어요. 먼저 자녀를 등록해 주세요.',
      );
    }
    final count = await _ref
        .read(routineRepositoryProvider)
        .createRoutine(childId: child.childId, routine: routine);
    _ref.invalidate(routineCalendarProvider);
    return count;
  }
}
