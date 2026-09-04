import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// 워치 디바이스와의 BLE 연동을 감싸는 서비스.
///
/// GATT 서비스/캐릭터리스틱 UUID는 임베디드 팀과 스펙이 확정되면
/// 여기에 채워 넣는다. 지금은 스캔까지만 동작한다.
class BleService {
  BleService() : _ble = FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  Stream<DiscoveredDevice> scanForWatch() {
    return _ble.scanForDevices(withServices: const []);
  }

  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    return _ble.connectToDevice(id: deviceId);
  }
}
