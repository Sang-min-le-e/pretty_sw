import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_user.dart';

abstract class UserRepository {
  /// `docs/API.md` 5장. `name`이 `null`이면 온보딩 1차(보호자 성명)를
  /// 아직 안 마친 계정 — 로그인 직후 이 값으로 온보딩 필요 여부를
  /// 가른다.
  Future<AuthUser> getMe();

  /// 온보딩 1차("보호자 성명")가 이 API를 그대로 쓴다(`docs/API.md` 5장).
  Future<AuthUser> updateMe({required String name});
}

class ApiUserRepository implements UserRepository {
  ApiUserRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthUser> getMe() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<AuthUser> updateMe({required String name}) async {
    try {
      final response = await _apiClient.dio.patch('/users/me', data: {'name': name});
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
