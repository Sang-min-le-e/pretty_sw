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

  /// `docs/API.md` 5장 `DELETE /users/me` — 회원 탈퇴. 본문 없이 `204`가 온다.
  /// 서버가 계정의 `access_uuid`를 무효화하고 자녀·기기·루틴·양식을 한 번에
  /// soft delete한다. 기기 쪽 로컬 데이터 정리는 이 저장소의 일이 아니라
  /// `AccountActions.withdraw`가 맡는다.
  Future<void> deleteUser();
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

  @override
  Future<void> deleteUser() async {
    try {
      await _apiClient.dio.delete('/users/me');
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
