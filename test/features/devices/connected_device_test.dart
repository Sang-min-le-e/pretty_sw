import 'package:flutter_test/flutter_test.dart';
import 'package:routine_app/features/devices/domain/connected_device.dart';

void main() {
  test('ACTIVE 기기를 파싱한다', () {
    final d = ConnectedDevice.fromJson({
      'deviceId': 55,
      'nickname': '아이 시계',
      'status': 'ACTIVE',
      'battery': 78,
      'firmwareVersion': '1.0.3',
      'lastSyncedAt': '2026-09-01T07:55:00Z',
      'pairedAt': '2026-08-20T10:12:00Z',
    });
    expect(d.deviceId, 55);
    expect(d.name, '아이 시계');
    expect(d.isActive, isTrue);
    expect(d.battery, 78);
    expect(d.lastSyncedAt, DateTime.utc(2026, 9, 1, 7, 55));
  });

  test('PENDING 기기는 battery 등이 전부 null이어도 파싱된다', () {
    final d = ConnectedDevice.fromJson({
      'deviceId': 56,
      'nickname': '예비 기기',
      'status': 'PENDING',
      'battery': null,
      'firmwareVersion': null,
      'lastSyncedAt': null,
      'pairedAt': null,
    });
    expect(d.isActive, isFalse);
    expect(d.battery, isNull);
    expect(d.pairedAt, isNull);
  });

  test('페어링 응답의 코드는 앞자리 0을 유지한다', () {
    final t = PairingTicket.fromJson({
      'deviceId': 55,
      'pairingCode': '0012345678',
      'expiresAt': '2026-09-01T08:40:00Z',
      'status': 'PENDING',
    });
    expect(t.pairingCode, '0012345678');
    expect(t.deviceId, 55);
  });
}
