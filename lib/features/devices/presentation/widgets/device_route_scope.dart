import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/device_providers.dart';
import '../../domain/connected_device.dart';

/// `/devices/:deviceId/...` 화면들이 URL의 기기 번호로 [ConnectedDevice]를 찾아
/// 넘겨받게 해 주는 래퍼. 목록을 불러오는 동안엔 로딩을, 기기가 없으면(삭제됨 등)
/// 기기 목록 화면으로 돌려보낸다.
class DeviceRouteScope extends ConsumerWidget {
  const DeviceRouteScope({super.key, required this.deviceId, required this.builder});

  final String deviceId;
  final Widget Function(BuildContext context, ConnectedDevice device) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);
    final id = int.tryParse(deviceId);
    final device = devices.value?.where((d) => d.deviceId == id).firstOrNull;
    if (device != null) return builder(context, device);

    if (devices.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/devices');
      });
    }
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
