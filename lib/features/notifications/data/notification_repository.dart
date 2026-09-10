import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
}

/// Hive 기반 로컬 구현체. 지금은 이 박스에 알림을 써 넣는 곳이 없어서
/// (알림을 발생시키는 기능이 아직 없다) 항상 빈 목록을 돌려준다 — 홈 화면
/// 벨 뱃지가 "알림이 없으면 숫자를 안 보여주는" 정상 상태로 시작하는 이유.
class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository(this._storage);

  static const _boxName = 'notifications';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final box = await _box;
    return box.values
        .map((raw) => AppNotification.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }
}
