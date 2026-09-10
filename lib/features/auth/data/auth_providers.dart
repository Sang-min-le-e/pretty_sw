import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';
import 'auth_session_repository.dart';
import 'user_repository.dart';

final _localStorageServiceProvider = Provider((ref) => LocalStorageService());

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  return LocalAuthSessionRepository(ref.watch(_localStorageServiceProvider));
});

/// 앱 전체가 공유하는 단 하나의 Dio 클라이언트. [AuthSessionRepository]에
/// 저장된 `accessUuid`를 매 요청에 자동으로 실어 보내도록 여기서 연결한다
/// — `api_client.dart`(core)는 세션이 어디 저장되는지 몰라도 되고, 이
/// provider가 그 둘을 이어주는 유일한 자리다.
final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(authSessionRepositoryProvider);
  return ApiClient(getAccessUuid: session.getAccessUuid);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(apiClientProvider), ref.watch(authSessionRepositoryProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return ApiUserRepository(ref.watch(apiClientProvider));
});

/// 로그인한 계정 정보(`GET /users/me`)를 캐싱해서 여러 화면(내 정보 헤더,
/// 사용자 설정, 프로필 수정)이 각자 다시 불러오지 않고 공유하게 한다.
/// 이름을 바꾸는 화면(`profile_edit_screen.dart`)은 저장 성공 후
/// `ref.invalidate(currentUserProvider)`로 이 캐시를 비워서 다음에 보는
/// 화면들이 최신 값을 다시 받아오게 만든다.
final currentUserProvider = FutureProvider<AuthUser>((ref) {
  return ref.watch(userRepositoryProvider).getMe();
});
