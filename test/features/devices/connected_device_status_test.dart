import 'package:flutter_test/flutter_test.dart';
import 'package:routine_app/features/devices/domain/connected_device.dart';

ConnectedDevice device({int? battery, DateTime? lastSyncedAt}) => ConnectedDevice(
      deviceId: 1,
      name: '예소',
      status: 'ACTIVE',
      battery: battery,
      firmwareVersion: '0.0.1',
      lastSyncedAt: lastSyncedAt,
      pairedAt: null,
    );

void main() {
  test('서버가 준 배터리를 그대로 보여주고, 없으면 --% 로 보여준다', () {
    expect(device(battery: 60).batteryLabel, '60%');
    expect(device().batteryLabel, '--%');
  });

  test('마지막 동기화가 10분 안이면 온라인, 아니면 오프라인', () {
    final now = DateTime.now();
    expect(device(lastSyncedAt: now.subtract(const Duration(minutes: 3))).isOnline, isTrue);
    expect(device(lastSyncedAt: now.subtract(const Duration(minutes: 30))).isOnline, isFalse);
    expect(device().isOnline, isFalse);
  });

  test('동기화 문구', () {
    final now = DateTime.now();
    expect(device().syncLabel, '동기화 기록 없음');
    expect(device(lastSyncedAt: now.subtract(const Duration(seconds: 20))).syncLabel, '방금 동기화됨');
    expect(device(lastSyncedAt: now.subtract(const Duration(minutes: 3, seconds: 5))).syncLabel, '3분전 동기화됨');
    expect(device(lastSyncedAt: now.subtract(const Duration(hours: 2, minutes: 1))).syncLabel, '2시간전 동기화됨');
    expect(device(lastSyncedAt: now.subtract(const Duration(days: 2, hours: 1))).syncLabel, '2일전 동기화됨');
  });
}
