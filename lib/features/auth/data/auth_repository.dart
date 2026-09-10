import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_user.dart';
import 'auth_session_repository.dart';

abstract class AuthRepository {
  /// `docs/API.md` 4장 — 이메일 형식만 검사하고 실제 발송·인증은 없다.
  /// 성공하면 가입과 동시에 로그인 상태가 된다(서버가 `accessUuid`를
  /// 같이 내려준다).
  Future<AuthUser> signup({required String email, required String password});

  /// 로그인할 때마다 서버가 `accessUuid`를 새로 발급하고 이전 값을
  /// 무효로 만든다 — 그래서 한 계정은 항상 한 기기에서만 로그인 상태다.
  Future<AuthUser> login({required String email, required String password});

  /// 서버의 `access_uuid`를 비우고, 기기에 저장해둔 값도 지운다.
  Future<void> logout();
}

/// Dio 기반 구현체. 회원가입/로그인 응답의 `accessUuid`를
/// [AuthSessionRepository]에 저장하는 것까지 이 저장소가 맡는다 —
/// 화면 쪽에서 "로그인 API를 부르고, 그 결과를 또 어딘가에 저장"하는
/// 두 단계를 따로 챙기지 않아도 되게 하기 위해서다.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._apiClient, this._session);

  final ApiClient _apiClient;
  final AuthSessionRepository _session;

  @override
  Future<AuthUser> signup({required String email, required String password}) {
    return _authenticate('/auth/signup', email: email, password: password);
  }

  @override
  Future<AuthUser> login({required String email, required String password}) {
    return _authenticate('/auth/login', email: email, password: password);
  }

  Future<AuthUser> _authenticate(
    String path, {
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        path,
        data: {'email': email, 'password': password},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      await _session.saveAccessUuid(data['accessUuid'] as String);
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } on DioException {
      // 서버 호출이 실패해도(네트워크 오류 등) 기기 쪽 값은 지운다 —
      // "로그아웃했는데 다음에 켰을 때도 로그인돼 있는" 상황을 막기
      // 위해서다. 아래 finally에서 로컬 세션을 정리한다.
    } finally {
      await _session.clearAccessUuid();
    }
  }
}
