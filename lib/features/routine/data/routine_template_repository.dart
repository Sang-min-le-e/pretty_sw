import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/routine_template.dart';

abstract class RoutineTemplateRepository {
  /// `docs/API.md` 10장 `GET /children/:childId/routine-templates`.
  Future<List<RoutineTemplate>> getTemplates({required int childId});

  /// `POST /children/:childId/routine-templates` — 이름·시각·할 일을 양식으로
  /// 저장한다. 반복 정보는 양식에 없다(반복은 루틴을 만들 때 정한다).
  Future<void> createTemplate({
    required int childId,
    required String title,
    required String startTime,
    required String endTime,
    required List<String> steps,
  });

  /// `DELETE /routine-templates/:templateId` — soft delete. 이 양식으로 이미 만든
  /// 루틴은 그대로 남는다.
  Future<void> deleteTemplate({required int templateId});
}

/// Dio 기반 구현체. 이전의 Hive 구현(`LocalRoutineTemplateRepository`)을 대체했다.
class ApiRoutineTemplateRepository implements RoutineTemplateRepository {
  ApiRoutineTemplateRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<RoutineTemplate>> getTemplates({required int childId}) async {
    try {
      final response = await _apiClient.dio.get('/children/$childId/routine-templates');
      return (response.data['data'] as List)
          .map((raw) => RoutineTemplate.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> createTemplate({
    required int childId,
    required String title,
    required String startTime,
    required String endTime,
    required List<String> steps,
  }) async {
    try {
      await _apiClient.dio.post(
        '/children/$childId/routine-templates',
        data: {
          'title': title,
          'startTime': startTime,
          'endTime': endTime,
          'smallRoutines': [
            for (var i = 0; i < steps.length; i++) {'title': steps[i], 'order': i + 1},
          ],
        },
      );
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> deleteTemplate({required int templateId}) async {
    try {
      await _apiClient.dio.delete('/routine-templates/$templateId');
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
