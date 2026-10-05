import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../devices/data/device_providers.dart';
import '../../notifications/data/notification_providers.dart';
import '../../profile/data/avatar_providers.dart';
import '../../routine/data/routine_providers.dart';
import '../../routine/data/routine_template_providers.dart';
import 'auth_providers.dart';

final accountActionsProvider = Provider((ref) => AccountActions(ref));

/// 계정 단위로 일어나는 일 중 서버 호출과 기기 안 정리를 함께 해야 하는 것.
class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  /// 회원 탈퇴. 서버(`DELETE /users/me`)를 **먼저** 부르고, 성공했을 때만
  /// 기기 안 데이터를 지운다 — 서버 호출이 실패(네트워크 오류 등)했는데
  /// 로컬만 지워 버리면 계정은 남아 있고 기기 데이터만 사라진다.
  ///
  /// 예외: 이미 탈퇴한 계정(`USER_NOT_FOUND`)이거나 세션이 무효(401)이면
  /// 서버 쪽은 이미 정리된 상태라 다시 시도해도 같은 결과이므로, 막히지
  /// 않게 로컬 정리까지 진행한다. 그 외 오류는 그대로 던져서 화면이 알린다.
  Future<void> withdraw() async {
    try {
      await _ref.read(userRepositoryProvider).deleteUser();
    } on ApiException catch (e) {
      final alreadyGone = e.code == 'USER_NOT_FOUND' || e.statusCode == 401;
      if (!alreadyGone) rethrow;
    }
    await _wipeLocalData();
  }

  /// 이 기기에 남아 있는 이 계정의 흔적을 전부 지운다: 프로필 사진 파일,
  /// Hive 박스 전체(로그인 세션 포함), 그리고 메모리에 캐시된 provider 값.
  /// 마지막 것을 빼먹으면 다음에 로그인한 계정에게 이전 계정의 이름·루틴이
  /// 앱을 다시 켜기 전까지 보일 수 있다.
  Future<void> _wipeLocalData() async {
    await _ref.read(avatarActionsProvider).deleteAvatarFile();
    await LocalStorageService().deleteAllBoxes();

    _ref.invalidate(currentUserProvider);
    _ref.invalidate(routineListProvider);
    _ref.invalidate(routineTemplateListProvider);
    _ref.invalidate(deviceListProvider);
    _ref.invalidate(selectedDeviceIndexProvider);
    _ref.invalidate(avatarPathProvider);
    _ref.invalidate(notificationListProvider);
  }
}
