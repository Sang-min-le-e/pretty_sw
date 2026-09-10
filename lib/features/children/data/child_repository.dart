import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/child.dart';

abstract class ChildRepository {
  /// 온보딩 2차(`docs/API.md` 6장 `POST /children`).
  Future<Child> createChild({
    required String name,
    required DateTime birthDate,
    required String relationship,
  });

  Future<List<Child>> getChildren();
}

class ApiChildRepository implements ChildRepository {
  ApiChildRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Child> createChild({
    required String name,
    required DateTime birthDate,
    required String relationship,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/children',
        data: {
          'name': name,
          'birthDate': _dateOnly(birthDate),
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

  /// `docs/API.md` 1-3 — 날짜는 `yyyy-MM-dd`만 받는다(시각 없음).
  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
