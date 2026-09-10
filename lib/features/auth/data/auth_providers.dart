import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
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
