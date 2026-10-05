import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_date.dart';
import '../../../core/network/api_exception.dart';
import '../domain/new_routine.dart';
import '../domain/routine.dart';

abstract class RoutineRepository {
  /// `docs/API.md` 9장 `GET /children/:childId/calendar` — [from]~[to] 사이의
  /// 루틴을 상세까지 통째로 돌려준다(날짜는 시각 없이 날짜만 의미가 있다).
  /// 서버가 날짜별로 묶어 주는 것을 루틴 하나씩 펼쳐 한 줄 목록으로 만든다.
  Future<List<Routine>> getCalendar({
    required int childId,
    required DateTime from,
    required DateTime to,
  });

  /// `POST /children/:childId/big-routines` — 반복 모드에 따라 서버가 날짜별
  /// 루틴을 한꺼번에 만든다. 실제로 만들어진 개수를 돌려준다(요일이 하루도
  /// 없는 `WEEKLY` 같은 경우는 오류 없이 0).
  Future<int> createRoutine({required int childId, required NewRoutine routine});
}

/// Dio 기반 구현체. 이전의 Hive 구현(`LocalRoutineRepository`)을 대체했다.
class ApiRoutineRepository implements RoutineRepository {
  ApiRoutineRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Routine>> getCalendar({
    required int childId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/children/$childId/calendar',
        queryParameters: {'from': apiDate(from), 'to': apiDate(to)},
      );
      final routines = <Routine>[];
      for (final rawDay in response.data['data'] as List) {
        final day = rawDay as Map<String, dynamic>;
        final date = DateTime.parse(day['date'] as String);
        for (final rawRoutine in day['bigRoutines'] as List? ?? const []) {
          routines.add(Routine.fromCalendarJson(date, rawRoutine as Map<String, dynamic>));
        }
      }
      return routines;
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<int> createRoutine({required int childId, required NewRoutine routine}) async {
    try {
      final response = await _apiClient.dio.post(
        '/children/$childId/big-routines',
        data: routine.toJson(),
      );
      return response.data['data']['createdCount'] as int;
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
