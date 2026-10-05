import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_date.dart';
import '../../../core/network/api_exception.dart';
import '../domain/change_scope.dart';
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

  /// `PATCH /big-routines/:bigRoutineId` — 이름·시작·종료 시각만 고친다(날짜·반복·
  /// 할 일은 못 바꾼다). [scope]가 `series`면 같은 반복의 오늘 이후 날짜도 함께
  /// 바뀐다. 고친 뒤의 시각 짝도 서버가 검사한다(`ROUTINE_INVALID_TIME_RANGE`).
  Future<void> updateRoutine({
    required int bigRoutineId,
    required String title,
    required String startTime,
    required String endTime,
    required ChangeScope scope,
  });

  /// `DELETE /big-routines/:bigRoutineId` — soft delete(이행률 통계 보존을 위해
  /// 물리 삭제 안 함). [scope]가 `series`면 같은 반복의 오늘 이후도 지운다.
  Future<void> deleteRoutine({required int bigRoutineId, required ChangeScope scope});

  /// `POST /big-routines/:bigRoutineId/small-routines` — 할 일 하나 추가. [scope]가
  /// `series`면 같은 반복의 오늘 이후 날짜에도 같은 할 일이 추가된다.
  Future<void> addSmallRoutine({
    required int bigRoutineId,
    required String title,
    required ChangeScope scope,
  });

  /// `PATCH /small-routines/:smallRoutineId` — 이름만 고친다. `scope`가 없어서
  /// **그 날짜의 그 할 일 하나**에만 적용된다.
  Future<void> renameSmallRoutine({required int smallRoutineId, required String title});

  /// `DELETE /small-routines/:smallRoutineId` — 그 날짜의 그 할 일 하나만 지운다.
  Future<void> deleteSmallRoutine({required int smallRoutineId});

  /// `PUT /big-routines/:bigRoutineId/small-routines/order` — 이 루틴의 할 일
  /// **전부**를 [orderedIds] 순서(1, 2, 3…)로 다시 줄 세운다. 하나라도 빠지면
  /// 서버가 `ROUTINE_ORDER_MISMATCH`로 거절한다.
  Future<void> reorderSmallRoutines({
    required int bigRoutineId,
    required List<int> orderedIds,
  });
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

  @override
  Future<void> updateRoutine({
    required int bigRoutineId,
    required String title,
    required String startTime,
    required String endTime,
    required ChangeScope scope,
  }) async {
    try {
      await _apiClient.dio.patch(
        '/big-routines/$bigRoutineId',
        queryParameters: {'scope': scope.code},
        data: {'title': title, 'startTime': startTime, 'endTime': endTime},
      );
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> deleteRoutine({required int bigRoutineId, required ChangeScope scope}) async {
    try {
      await _apiClient.dio.delete(
        '/big-routines/$bigRoutineId',
        queryParameters: {'scope': scope.code},
      );
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> addSmallRoutine({
    required int bigRoutineId,
    required String title,
    required ChangeScope scope,
  }) async {
    try {
      await _apiClient.dio.post(
        '/big-routines/$bigRoutineId/small-routines',
        queryParameters: {'scope': scope.code},
        data: {'title': title},
      );
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> renameSmallRoutine({required int smallRoutineId, required String title}) async {
    try {
      await _apiClient.dio.patch('/small-routines/$smallRoutineId', data: {'title': title});
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> deleteSmallRoutine({required int smallRoutineId}) async {
    try {
      await _apiClient.dio.delete('/small-routines/$smallRoutineId');
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> reorderSmallRoutines({
    required int bigRoutineId,
    required List<int> orderedIds,
  }) async {
    try {
      // 요청 본문의 최상위가 배열이다(`docs/API.md` 9장 확정). 배열에 담긴
      // 차례가 아니라 `order` 값이 순서를 정하므로 1부터 번호를 매겨 보낸다.
      await _apiClient.dio.put(
        '/big-routines/$bigRoutineId/small-routines/order',
        data: [
          for (var i = 0; i < orderedIds.length; i++)
            {'smallRoutineId': orderedIds[i], 'order': i + 1},
        ],
      );
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
