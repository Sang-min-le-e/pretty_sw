import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/app_notification.dart';
import 'notification_repository.dart';

// 다른 기능의 `localStorageServiceProvider`와 별개의 provider 인스턴스지만,
// `LocalStorageService`가 상태 없이 `Hive.openBox`만 감싸는 얇은 래퍼라
// 두 인스턴스가 같은 박스를 열어도 문제가 없다.
final _localStorageServiceProvider = Provider((ref) => LocalStorageService());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return LocalNotificationRepository(ref.watch(_localStorageServiceProvider));
});

final notificationListProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

/// 홈 화면 벨 아이콘 뱃지에 쓰는 개수. 0이면 뱃지 자체를 안 그린다.
final notificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationListProvider).value?.length ?? 0;
});
