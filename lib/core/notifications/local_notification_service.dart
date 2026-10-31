import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 기기(OS) 알림을 띄우는 얇은 래퍼. `flutter_local_notifications` 설정과
/// 권한 요청을 한곳에 모아서, 알림을 띄우는 쪽은 [show]만 부르면 된다.
class LocalNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static const _channel = AndroidNotificationDetails(
    'routine_done',
    '루틴 완료',
    channelDescription: '아이가 기기에서 할 일을 완료하면 알려줍니다.',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// 초기화 + 알림 권한 요청을 한 번만 한다. 권한을 거절했거나 초기화가
  /// 실패하면 `false`.
  Future<bool> _ensureReady() {
    return _ready ??= () async {
      try {
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
        );
        final ios = _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) {
          return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
        }
        final android = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          return await android.requestNotificationsPermission() ?? false;
        }
        return true;
      } catch (e) {
        debugPrint('로컬 알림 초기화 실패: $e');
        return false;
      }
    }();
  }

  Future<void> show({required int id, required String title, required String body}) async {
    if (!await _ensureReady()) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
