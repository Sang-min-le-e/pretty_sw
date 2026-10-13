import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'watch_gatt.dart';

/// 워치 디바이스와의 BLE 연동을 감싸는 서비스.
///
/// GATT 스펙(UUID, 전달 형식)은 [WatchGatt] / `docs/BLE_SPEC.md`.
class BleService {
  BleService() : _ble = FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  /// 워치 서비스 UUID를 광고하는 기기만 찾는다.
  Stream<DiscoveredDevice> scanForWatch() {
    return _ble.scanForDevices(withServices: [WatchGatt.service]);
  }

  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    return _ble.connectToDevice(id: deviceId);
  }

  /// [deviceId] 기기에 연결해 와이파이/페어링 정보를 쓰고 연결을 끊는다.
  ///
  /// 기기가 [WatchGatt.status] 로 `WIFI_FAIL`/`PARSE_ERROR` 를 알리면 예외를
  /// 던진다. 상태 알림이 없거나 늦어도 쓰기만 끝나면 정상 반환한다 — 페어링이
  /// 실제로 끝났는지는 서버 폴링(`GET /devices/:id` 가 `ACTIVE`)이 판단한다.
  Future<void> provisionWifi({
    required String deviceId,
    required WifiProvisioningPayload payload,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration statusWait = const Duration(seconds: 3),
  }) async {
    final connected = Completer<void>();
    late final StreamSubscription<ConnectionStateUpdate> connection;
    connection = connectToDevice(deviceId).listen(
      (update) {
        if (update.connectionState == DeviceConnectionState.connected &&
            !connected.isCompleted) {
          connected.complete();
        }
      },
      onError: (Object e, StackTrace s) {
        if (!connected.isCompleted) connected.completeError(e, s);
      },
    );

    StreamSubscription<List<int>>? statusSub;
    try {
      await connected.future.timeout(connectTimeout);

      WatchStatus? result;
      statusSub = _ble
          .subscribeToCharacteristic(_characteristic(deviceId, WatchGatt.status))
          .listen((bytes) {
        final s = WatchStatus.parse(bytes);
        if (s == WatchStatus.wifiFail || s == WatchStatus.parseError) result = s;
      }, onError: (_) {
        // 상태 특성이 없는 기기도 허용한다(쓰기만으로 진행).
      });

      final config = _characteristic(deviceId, WatchGatt.wifiConfig);
      for (final chunk in payload.toChunks()) {
        await _ble.writeCharacteristicWithResponse(config, value: chunk);
      }

      await Future<void>.delayed(statusWait);
      if (result != null) {
        throw StateError('기기가 오류를 알려 왔습니다: ${result!.wire}');
      }
    } finally {
      await statusSub?.cancel();
      await connection.cancel(); // 구독을 끊으면 연결이 해제된다.
    }
  }

  QualifiedCharacteristic _characteristic(String deviceId, Uuid characteristic) {
    return QualifiedCharacteristic(
      serviceId: WatchGatt.service,
      characteristicId: characteristic,
      deviceId: deviceId,
    );
  }
}
