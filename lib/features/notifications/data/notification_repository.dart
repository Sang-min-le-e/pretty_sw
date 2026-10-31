import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();

  Future<void> add(AppNotification notification);

  /// 알림 한 건을 지운다(카드를 왼쪽으로 밀어 없앨 때).
  Future<void> remove(String id);

  /// 모든 알림을 읽음으로 바꾼다(알림 목록 화면을 열면 부른다).
  Future<void> markAllRead();

  /// [childId]의 할 일 중 이미 알림 대상으로 확인한(완료로 본) `smallRoutineId`들.
  /// 한 번도 저장한 적 없으면 `null` — 이때는 지금 완료된 것들을 알리지 않고
  /// 기준선으로만 저장해야 한다(첫 실행에 옛 완료분이 쏟아지는 걸 막는다).
  Future<Set<int>?> getSeenDoneIds(int childId);

  Future<void> saveSeenDoneIds(int childId, Set<int> ids);
}

/// Hive 기반 로컬 구현체. 알림은 기기에서 할 일 완료를 감지했을 때
/// (`completion_watcher.dart`) 쌓인다. 알림이 없으면 홈 화면 벨 뱃지는 숫자를
/// 보여주지 않는다.
class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository(this._storage);

  static const _boxName = 'notifications';
  static const _stateBoxName = 'notification_state';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);
  Future<Box<Map>> get _stateBox => _storage.openBox(_stateBoxName);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final box = await _box;
    return box.values
        .map((raw) => AppNotification.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<void> add(AppNotification notification) async {
    final box = await _box;
    await box.put(notification.id, notification.toMap());
  }

  @override
  Future<void> remove(String id) async {
    await (await _box).delete(id);
  }

  @override
  Future<void> markAllRead() async {
    final box = await _box;
    for (final key in box.keys.toList()) {
      final map = Map<String, dynamic>.from(box.get(key)!);
      if (map['read'] == true) continue;
      map['read'] = true;
      await box.put(key, map);
    }
  }

  @override
  Future<Set<int>?> getSeenDoneIds(int childId) async {
    final raw = (await _stateBox).get('seenDone_$childId');
    if (raw == null) return null;
    return (raw['ids'] as List).cast<int>().toSet();
  }

  @override
  Future<void> saveSeenDoneIds(int childId, Set<int> ids) async {
    await (await _stateBox).put('seenDone_$childId', {'ids': ids.toList()});
  }
}
