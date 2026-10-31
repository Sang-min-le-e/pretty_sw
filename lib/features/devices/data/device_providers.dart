import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (riverpod 3부터 별도 export)

import '../../../core/ble/watch_gatt.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../auth/data/auth_providers.dart';
import '../../children/data/child_providers.dart';
import '../../watch_connection/data/watch_connection_providers.dart';
import '../domain/connected_device.dart';
import 'device_color_repository.dart';
import 'device_repository.dart';
import 'wifi_credentials.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return ApiDeviceRepository(ref.watch(apiClientProvider));
});

/// 내 모든 자녀의 **연결 완료(`ACTIVE`)** 기기 목록(`deviceId` 순). 비어 있으면
/// "연결된 기기 없음" 상태를 뜻한다 — 홈 화면 `ConnectedDevicesCard`가 이 provider로
/// 빈 상태/목록 상태를 가른다. 아직 claim 전(`PENDING`)인 기기는 연결된 게 아니라서
/// 뺀다. Figma에서는 기기마다 학생이 하나씩 자동으로 생기고 "연결된 기기"에 전부
/// 나란히 보여서, 자녀 한 명이 아니라 모든 자녀의 기기를 모은다.
final deviceListProvider = FutureProvider<List<ConnectedDevice>>((ref) async {
  final children = ref.watch(childListProvider).value ?? const [];
  if (children.isEmpty) return const [];
  final repository = ref.watch(deviceRepositoryProvider);
  final perChild = await Future.wait(children.map((c) => repository.getDevices(c.childId)));
  return [
    for (final devices in perChild) ...devices.where((d) => d.isActive),
  ]..sort((a, b) => a.deviceId.compareTo(b.deviceId));
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

  /// 서버가 정한 페어링 코드 만료(10분). 이 안에 `ACTIVE`가 안 되면 실패로 본다.
  static const pairingTimeout = Duration(minutes: 10);
  static const pollInterval = Duration(seconds: 2);

  /// 새 기기를 페어링한다.
  ///
  /// 1) 서버에서 페어링 코드 발급 → 2) BLE로 기기에 와이파이/코드/서버 주소 전달 →
  /// 3) 기기가 와이파이에 붙어 서버에 `claim`할 때까지 `GET /devices/:id` 폴링
  /// (`PENDING → ACTIVE`). 중간에 실패하면 남은 `PENDING` 기기를 서버에서 지운다.
  ///
  /// [isCancelled]가 `true`를 돌려주면(화면을 벗어남 등) 폴링을 멈추고 예외를 던진다.
  Future<void> pairNewDevice({
    required String bleDeviceId,
    required String nickname,
    required String ssid,
    required String password,
    bool Function()? isCancelled,
    void Function(String step)? onStep,
  }) async {
    // Figma에는 학생 등록 단계가 없고 기기 이름이 곧 학생 이름이다. 서버는 기기를
    // 자녀에 붙이므로 기기마다 자녀를 하나 자동으로 만든다. 생년월일은 보내지
    // 않는다 — 서버가 필수로 요구하면 이 단계에서 서버 오류 문구가 그대로 보인다.
    onStep?.call('학생 정보를 만드는 중');
    final child = await _ref.read(childRepositoryProvider).createChild(
          name: nickname,
          relationship: 'ADMIN',
        );
    _ref.invalidate(childListProvider);
    _ref.read(selectedChildIdProvider.notifier).state = child.childId;

    final repository = _ref.read(deviceRepositoryProvider);

    onStep?.call('페어링 코드를 만드는 중');
    final ticket = await repository.createPairing(childId: child.childId, nickname: nickname);

    try {
      onStep?.call('기기에 와이파이 정보를 보내는 중');
      await _ref.read(bleServiceProvider).provisionWifi(
            deviceId: bleDeviceId,
            payload: WifiProvisioningPayload(
              ssid: ssid,
              password: password,
              pairingCode: ticket.pairingCode,
              serverUrl: resolveServerOrigin(),
            ),
          );

      onStep?.call('기기가 서버에 연결되길 기다리는 중');
      final deadline = DateTime.now().add(pairingTimeout);
      while (true) {
        if (isCancelled?.call() ?? false) throw StateError('페어링이 취소됐어요.');
        final device = await repository.getDevice(ticket.deviceId);
        if (device.isActive) {
          // 페어링이 끝난 와이파이는 "연결된 기기" 화면에 보여 주려고 남겨 둔다.
          try {
            await _ref
                .read(wifiCredentialsStoreProvider)
                .save(WifiCredentials(ssid: ssid, password: password));
            _ref.invalidate(wifiCredentialsProvider);
          } catch (_) {} // 저장 실패가 페어링 성공을 되돌리진 않는다.
          break;
        }
        if (DateTime.now().isAfter(deadline)) {
          throw TimeoutException('기기가 시간 안에 연결되지 않았어요.', pairingTimeout);
        }
        await Future<void>.delayed(pollInterval);
      }
    } catch (_) {
      try {
        await repository.deleteDevice(ticket.deviceId); // 남은 PENDING 정리
      } catch (_) {}
      rethrow;
    } finally {
      _ref.invalidate(deviceListProvider);
    }
  }

  Future<void> renameDevice(int deviceId, String nickname) async {
    await _ref.read(deviceRepositoryProvider).renameDevice(deviceId, nickname);
    _ref.invalidate(deviceListProvider);
  }

  Future<void> deleteDevice(int deviceId) async {
    await _ref.read(deviceRepositoryProvider).deleteDevice(deviceId);
    _ref.invalidate(deviceListProvider);
    // 지운 기기가 고른 색이 남아 있으면 안 되므로 같이 지운다.
    await _ref.read(deviceColorRepositoryProvider).remove(deviceId);
    _ref.invalidate(deviceColorOverridesProvider);
  }

  /// 기기 설정에서 고른 색(팔레트 인덱스)을 이 휴대폰에 저장한다.
  Future<void> setDeviceColor(int deviceId, int colorIndex) async {
    await _ref.read(deviceColorRepositoryProvider).setColor(deviceId, colorIndex);
    _ref.invalidate(deviceColorOverridesProvider);
  }
}

final _localStorageServiceProvider = Provider((ref) => LocalStorageService());

final deviceColorRepositoryProvider = Provider<DeviceColorRepository>((ref) {
  return LocalDeviceColorRepository(ref.watch(_localStorageServiceProvider));
});

/// 사용자가 직접 고른 기기 색(`deviceId → 팔레트 인덱스`).
final deviceColorOverridesProvider = FutureProvider<Map<int, int>>((ref) {
  return ref.watch(deviceColorRepositoryProvider).getAll();
});

/// [deviceId] 기기에 칠할 팔레트 인덱스. 기기 설정에서 고른 색이 있으면 그
/// 색, 없으면 등록 순번 색(1번째 연두 → 2번째 흰색 → 3번째 보라 순환)이다.
/// 홈 캐러셀·기기 관리 그리드·상세·설정·"연결된 기기" 점이 전부 이걸 써서
/// 같은 기기는 어느 화면에서나 같은 색으로 보인다.
final deviceColorIndexProvider = Provider.family<int, int>((ref, deviceId) {
  final picked = ref.watch(deviceColorOverridesProvider).value?[deviceId];
  if (picked != null) return picked;
  final devices = ref.watch(deviceListProvider).value ?? const [];
  final position = devices.indexWhere((d) => d.deviceId == deviceId);
  return position < 0 ? 0 : position;
});
