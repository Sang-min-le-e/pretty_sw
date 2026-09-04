import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../watch_connection/data/watch_connection_providers.dart';
import '../data/onboarding_providers.dart';

/// 초기 설정 3차: 페어링 + 디바이스 서버 등록.
///
/// Figma 노트 원문: "페어링까지 완료 후 메인창(4번)으로 이동" — 그래서 이 화면의
/// 역할은 "워치 스캔 -> 하나 선택 -> 완료 처리 -> 대시보드로 이동" 하나뿐이다.
///
/// [watchScanProvider]는 이미 워치 연결(watch_connection) 기능에 만들어져 있던
/// BLE 스캔 스트림을 그대로 재사용한다. 온보딩 전용으로 새로 만들지 않은 이유는,
/// "워치를 찾는다"는 동작 자체는 온보딩 때든 나중에 설정 화면에서 재페어링할 때든
/// 완전히 같은 로직이기 때문이다 — 로직을 두 군데에 복사하면 나중에 GATT 스펙이
/// 확정돼서 스캔 필터링 조건이 바뀔 때 한쪽을 고치고 한쪽을 까먹는 버그가 생기기 쉽다.
class DevicePairingScreen extends ConsumerWidget {
  const DevicePairingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingActionsProvider).completePairing();
    if (!context.mounted) return;
    // 온보딩 스택(로그인->보호자->자녀->페어링)을 전부 지우고 대시보드로 이동한다.
    // push 대신 go를 쓰는 이유: go는 현재 라우트 스택을 지정한 경로로 통째로
    // 바꿔버려서, 사용자가 대시보드에서 "뒤로가기"를 눌러도 온보딩 화면으로
    // 다시 돌아가지 않게 만들어준다 (온보딩은 한 번만 하면 되는 흐름이므로).
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanResult = ref.watch(watchScanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('워치 페어링')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('워치의 전원을 켜고 가까이 두면 자동으로 검색돼요.'),
              const SizedBox(height: 16),
              Expanded(
                child: scanResult.when(
                  data: (device) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.watch),
                      title: Text(device.name.isEmpty ? '(이름 없음)' : device.name),
                      subtitle: Text(device.id),
                      trailing: FilledButton(
                        onPressed: () => _completeOnboarding(context, ref),
                        child: const Text('이 기기로 연결'),
                      ),
                    ),
                  ),
                  loading: () => const Center(child: Text('주변 기기를 스캔 중이에요...')),
                  error: (error, stack) => Center(child: Text('스캔 실패: $error')),
                ),
              ),
              // 임베디드 팀의 워치 시제품이 아직 없거나 GATT 스펙 확정 전에도
              // 앱 화면 전체 흐름을 테스트할 수 있어야 해서 넣어둔 임시 버튼.
              // 실제 하드웨어 연동이 끝나면 이 버튼은 지워도 된다.
              TextButton(
                onPressed: () => _completeOnboarding(context, ref),
                child: const Text('워치 없이 건너뛰기 (임시)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
