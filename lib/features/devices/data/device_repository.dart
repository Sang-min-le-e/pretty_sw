import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/connected_device.dart';

abstract class DeviceRepository {
  Future<List<ConnectedDevice>> getDevices();
  Future<void> addDevice(ConnectedDevice device);
}

/// Hive 기반 로컬 구현체. 실제 기기 페어링(BLE)이 붙기 전까지는, "기기
/// 추가하기" 흐름들이 이걸로 연결된 기기 목록을 흉내 낸다.
class LocalDeviceRepository implements DeviceRepository {
  LocalDeviceRepository(this._storage);

  static const _boxName = 'devices';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<List<ConnectedDevice>> getDevices() async {
    final box = await _box;
    return box.values
        .map((raw) => ConnectedDevice.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<void> addDevice(ConnectedDevice device) async {
    final box = await _box;
    await box.put(device.id, device.toMap());
  }
}
