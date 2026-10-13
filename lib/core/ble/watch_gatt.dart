import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// 앱 ↔ 워치 BLE(GATT) 스펙. 기기 쪽 펌웨어도 이 값을 그대로 따라야 한다.
/// 사람이 읽는 설명은 `docs/BLE_SPEC.md`.
class WatchGatt {
  const WatchGatt._();

  /// 기기가 광고(advertising)에 반드시 넣는 서비스. 앱은 이 UUID로 스캔한다.
  static final service = Uuid.parse('7f3a0001-5d2e-4c1b-9a6f-8e4b2c1d0a00');

  /// 앱 → 기기. 와이파이/페어링 정보를 쓰는(write with response) 특성.
  static final wifiConfig = Uuid.parse('7f3a0002-5d2e-4c1b-9a6f-8e4b2c1d0a00');

  /// 기기 → 앱. 처리 결과를 알리는(notify) 특성. 없어도 페어링은 된다.
  static final status = Uuid.parse('7f3a0003-5d2e-4c1b-9a6f-8e4b2c1d0a00');

  /// 한 번에 쓰는 바이트 수. MTU 협상 없이도 안전한 최소값(기본 ATT MTU 23 - 3).
  static const defaultChunkSize = 20;

  /// 페이로드의 끝을 알리는 바이트(`\n`). 기기는 이 바이트가 올 때까지 이어 붙인다.
  static const terminator = 0x0A;
}

/// 기기가 [WatchGatt.status] 로 알려 주는 값(UTF-8 문자열).
enum WatchStatus {
  received('RECEIVED'),
  wifiOk('WIFI_OK'),
  wifiFail('WIFI_FAIL'),
  parseError('PARSE_ERROR');

  const WatchStatus(this.wire);
  final String wire;

  static WatchStatus? parse(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    for (final s in values) {
      if (s.wire == text) return s;
    }
    return null;
  }
}

/// 앱이 기기에 넘기는 내용. UTF-8 JSON 한 줄 + 끝 표시(`\n`).
class WifiProvisioningPayload {
  WifiProvisioningPayload({
    required this.ssid,
    required this.password,
    required this.pairingCode,
    required this.serverUrl,
  }) {
    if (ssid.isEmpty) throw ArgumentError('ssid가 비어 있습니다.');
    if (!RegExp(r'^\d{10}$').hasMatch(pairingCode)) {
      throw ArgumentError('pairingCode는 숫자 10자리 문자열이어야 합니다: $pairingCode');
    }
  }

  final String ssid;
  final String password;

  /// 서버가 발급한 10자리 숫자. 앞자리가 0일 수 있어 **문자열**로 다룬다.
  final String pairingCode;

  /// 기기가 `claim`/`sync`를 보낼 서버 주소(경로 없이), 예: `http://192.168.0.10:8080`.
  final String serverUrl;

  Map<String, String> toJson() => {
        'ssid': ssid,
        'password': password,
        'pairingCode': pairingCode,
        'serverUrl': serverUrl,
      };

  /// 전송할 전체 바이트(JSON + `\n`).
  List<int> toBytes() => [...utf8.encode(jsonEncode(toJson())), WatchGatt.terminator];

  /// [toBytes] 를 [chunkSize] 바이트씩 순서대로 나눈다.
  List<List<int>> toChunks({int chunkSize = WatchGatt.defaultChunkSize}) {
    if (chunkSize <= 0) throw ArgumentError.value(chunkSize, 'chunkSize');
    final bytes = toBytes();
    return [
      for (var i = 0; i < bytes.length; i += chunkSize)
        bytes.sublist(i, i + chunkSize > bytes.length ? bytes.length : i + chunkSize),
    ];
  }
}
