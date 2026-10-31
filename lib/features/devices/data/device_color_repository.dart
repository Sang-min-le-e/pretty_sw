import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';

/// 사용자가 기기 설정에서 고른 기기 색(팔레트 인덱스)을 기기별로 저장하는
/// 저장소. 서버 기기 정보(`ConnectedDevice`)에 색 필드가 없어서, 프로필
/// 사진과 같은 "로컬 우선" 패턴으로 이 휴대폰의 Hive에만 남긴다 — 다른
/// 휴대폰이나 재설치 후에는 고른 적 없는 것으로 보고 등록 순번 색을 쓴다.
abstract class DeviceColorRepository {
  /// `deviceId → 팔레트 인덱스`. 고른 적 없는 기기는 들어 있지 않다.
  Future<Map<int, int>> getAll();
  Future<void> setColor(int deviceId, int colorIndex);
  Future<void> remove(int deviceId);
}

class LocalDeviceColorRepository implements DeviceColorRepository {
  LocalDeviceColorRepository(this._storage);

  static const _boxName = 'device_colors';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<Map<int, int>> getAll() async {
    final box = await _box;
    return {
      for (final key in box.keys)
        if (key is int && box.get(key)?['color'] is int) key: box.get(key)!['color'] as int,
    };
  }

  @override
  Future<void> setColor(int deviceId, int colorIndex) async {
    final box = await _box;
    // Box<Map>만 열 수 있어서 값 하나도 {'color': ...}로 감싼다(avatar_repository 참고).
    await box.put(deviceId, {'color': colorIndex});
  }

  @override
  Future<void> remove(int deviceId) async {
    final box = await _box;
    await box.delete(deviceId);
  }
}
