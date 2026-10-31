import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider

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

/// 최신 알림이 맨 위로 오도록 정렬한 전체 알림.
final notificationListProvider = FutureProvider<List<AppNotification>>((ref) async {
  final list = await ref.watch(notificationRepositoryProvider).getNotifications();
  return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// 홈 화면 벨 아이콘 뱃지에 쓰는 **읽지 않은** 알림 수. 0이면 뱃지 자체를 안 그린다.
final notificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationListProvider).value ?? const [];
  return list.where((n) => !n.read).length;
});

/// 방금 도착해서 화면 위에 잠깐 띄울(토스트) 알림. 토스트가 3초 뒤 내려가면 다시
/// `null`이 된다. `NotificationToastHost`가 이 값을 보고 그린다.
final incomingNotificationProvider = StateProvider<AppNotification?>((ref) => null);
