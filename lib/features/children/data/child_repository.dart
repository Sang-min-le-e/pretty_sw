import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/child.dart';

abstract class ChildRepository {
  /// 온보딩 2차(`docs/API.md` 6장 `POST /children`).
  Future<Child> createChild({
    required String name,
    required String relationship,
  });

  Future<List<Child>> getChildren();

  /// `DELETE /children/:childId` — 자녀 삭제(soft delete, 204).
  Future<void> deleteChild(int childId);
}

class ApiChildRepository implements ChildRepository {
  ApiChildRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Child> createChild({
    required String name,
    required String relationship,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/children',
        data: {
          'name': name,
          'relationship': relationship,
        },
      );
      return Child.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<List<Child>> getChildren() async {
    try {
      final response = await _apiClient.dio.get('/children');
      return (response.data['data'] as List)
          .map((raw) => Child.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> deleteChild(int childId) async {
    try {
      await _apiClient.dio.delete('/children/$childId');
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
