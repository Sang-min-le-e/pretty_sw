import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (riverpod 3부터 별도 export)

import '../../../core/storage/local_storage_service.dart';
import '../domain/connected_device.dart';
import 'device_repository.dart';

// 루틴 기능의 `localStorageServiceProvider`와 별개의 provider 인스턴스지만,
// `LocalStorageService`가 상태 없이 `Hive.openBox`만 감싸는 얇은 래퍼라
// 두 인스턴스가 같은 박스를 열어도 문제가 없다.
final _localStorageServiceProvider = Provider((ref) => LocalStorageService());

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return LocalDeviceRepository(ref.watch(_localStorageServiceProvider));
});

/// 연결된 기기 전체 목록(등록 순서). 비어 있으면 "연결된 기기 없음" 상태를
/// 뜻한다 — 홈 화면 `ConnectedDevicesCard`가 이 provider로 빈 상태/목록
/// 상태를 가른다.
final deviceListProvider = FutureProvider<List<ConnectedDevice>>((ref) async {
  final devices = await ref.watch(deviceRepositoryProvider).getDevices();
  return devices..sort((a, b) => a.connectedAt.compareTo(b.connectedAt));
});

/// 홈 화면 캐러셀에서 지금 보고 있는 기기의 [deviceListProvider] 안
/// 인덱스. 화면 쪽에서 목록 길이로 나머지 연산(모듈로)해서 넘겨받아
/// 안전 범위로 감싸 쓴다(기기가 삭제돼 목록이 줄어들어도 범위를
/// 벗어나지 않게).
final selectedDeviceIndexProvider = StateProvider<int>((ref) => 0);

final deviceActionsProvider = Provider((ref) => DeviceActions(ref));

class DeviceActions {
  DeviceActions(this._ref);

  final Ref _ref;

  /// [name]으로 새 기기를 하나 등록한다. "기기 추가하기"(내 기기 페어링)와
  /// "연결 기기 추가"(가족 구성원 기기 추가) 두 흐름이 모두 이걸 부른다.
  Future<void> addDevice(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _ref.read(deviceRepositoryProvider).addDevice(
          ConnectedDevice(id: id, name: name, connectedAt: DateTime.now()),
        );
    _ref.invalidate(deviceListProvider);
  }
}
