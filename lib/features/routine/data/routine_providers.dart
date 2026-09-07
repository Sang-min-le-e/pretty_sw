import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/routine.dart';
import 'routine_repository.dart';

final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return LocalRoutineRepository(ref.watch(localStorageServiceProvider));
});

final routineListProvider = FutureProvider<List<Routine>>((ref) {
  return ref.watch(routineRepositoryProvider).getRoutines();
});

/// 달력에서 선택한 날짜(연/월/일)에 해당하는 루틴만 걸러서 시작 시각
/// 오름차순으로 정렬해 돌려준다. `.family`라서 화면에서
/// `ref.watch(routinesForDateProvider(selectedDate))`처럼 원하는 날짜를
/// 넘기면 그 날짜 전용 목록을 얻는다.
///
/// [routineListProvider]가 아직 로딩 중이거나 실패했으면 빈 목록으로
/// 취급한다 — 달력 화면 자체는 로딩 스피너 없이 "루틴 없음"으로 보이면
/// 되고, 데이터가 도착하면 이 provider가 자동으로 다시 계산된다.
final routinesForDateProvider = Provider.family<List<Routine>, DateTime>((
  ref,
  date,
) {
  final all = ref.watch(routineListProvider).value ?? const [];
  final sameDay = all
      .where(
        (r) =>
            r.dateTime.year == date.year &&
            r.dateTime.month == date.month &&
            r.dateTime.day == date.day,
      )
      .toList();
  sameDay.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return sameDay;
});

/// [month]가 속한 한 달 동안, "일(day) → 그날 루틴 개수" 맵을 만들어준다.
/// 달력 칸 아래에 표시하는 작은 회색 배지(예: 8일 아래 "3")가 이 값을 쓴다.
/// 루틴이 없는 날은 맵에 키 자체가 없다(0을 넣지 않음).
final routineCountsByDayProvider = Provider.family<Map<int, int>, DateTime>((
  ref,
  month,
) {
  final all = ref.watch(routineListProvider).value ?? const [];
  final counts = <int, int>{};
  for (final routine in all) {
    if (routine.dateTime.year == month.year &&
        routine.dateTime.month == month.month) {
      counts[routine.dateTime.day] = (counts[routine.dateTime.day] ?? 0) + 1;
    }
  }
  return counts;
});
