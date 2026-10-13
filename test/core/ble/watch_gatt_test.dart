import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_app/core/ble/watch_gatt.dart';

void main() {
  WifiProvisioningPayload payload({String code = '0012345678'}) =>
      WifiProvisioningPayload(
        ssid: '우리집 WiFi',
        password: 'pw 1234',
        pairingCode: code,
        serverUrl: 'http://192.168.0.10:8080',
      );

  test('JSON 한 줄 + 끝 표시로 직렬화하고 앞자리 0을 유지한다', () {
    final bytes = payload().toBytes();
    expect(bytes.last, WatchGatt.terminator);
    final json = jsonDecode(utf8.decode(bytes.sublist(0, bytes.length - 1)));
    expect(json['pairingCode'], '0012345678');
    expect(json['ssid'], '우리집 WiFi');
    expect(json['serverUrl'], 'http://192.168.0.10:8080');
  });

  test('조각을 이어 붙이면 원본과 같고 각 조각은 chunkSize 이하', () {
    final p = payload();
    final chunks = p.toChunks(chunkSize: 20);
    expect(chunks.every((c) => c.isNotEmpty && c.length <= 20), isTrue);
    expect(chunks.expand((c) => c).toList(), p.toBytes());
  });

  test('pairingCode가 10자리 숫자가 아니면 거부한다', () {
    expect(() => payload(code: '123'), throwsArgumentError);
    expect(() => payload(code: '12345abcde'), throwsArgumentError);
  });

  test('기기 상태 문자열을 해석한다', () {
    expect(WatchStatus.parse(utf8.encode('WIFI_OK\n')), WatchStatus.wifiOk);
    expect(WatchStatus.parse(utf8.encode('???')), isNull);
  });
}
