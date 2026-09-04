import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/routine_providers.dart';
import '../domain/big_routine.dart';

/// 하단 탭바의 "홈" 탭 = 목업의 홈 화면("내 기기" 카드 + "기기 상태" 그리드).
///
/// 처음 구현에서는 "이번주/어제 미션 이행률(%)" 카드 두 개 + 캐릭터 성장 카드로
/// 짰었는데, 실제 목업을 보니 이 화면의 주인공은 **페어링된 워치 기기 자체**였다
/// (Tomo 아이콘, 온라인 상태, 위치/배터리/와이파이/미션 진행률/현재 루틴 카드).
/// "미션 성공 -> 캐릭터 성장" 컨셉은 이 화면이 아니라 워치 자체 화면 몫으로 보여서
/// (컨셉 메모: "화면에 도트 그래픽으로 미션이 뜸 -> 캐릭터 성장") 여기서는 뺐다.
/// [features/character] 쪽 로직은 나중에 워치 연동 데이터를 받을 때를 대비해서
/// 그대로 남겨뒀다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayRoutinesAsync = ref.watch(bigRoutinesForDateProvider(todayKey));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [Icon(Icons.watch), SizedBox(width: 8), Text('Tomo')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: '워치 연결',
            onPressed: () => context.push('/watch-connection'),
          ),
        ],
      ),
      body: todayRoutinesAsync.when(
        data: (routines) => _HomeBody(todayRoutines: routines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('불러오기 실패: $error')),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.todayRoutines});

  final List<BigRoutine> todayRoutines;

  /// "미션 진행률"을 목업처럼 "완료/전체" 분수로 보여준다 (퍼센트보다 지적장애인
  /// 당사자나 보호자가 한눈에 "몇 개 남았는지" 이해하기 쉬운 표현이라고 판단됨).
  (int done, int total) get _missionProgress {
    var done = 0;
    var total = 0;
    for (final routine in todayRoutines) {
      total += routine.smallRoutines.length;
      done += routine.smallRoutines.where((s) => s.isDone).length;
    }
    return (done, total);
  }

  BigRoutine? get _activeRoutine {
    final now = DateTime.now();
    for (final routine in todayRoutines) {
      if (routine.isActiveAt(now)) return routine;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final (done, total) = _missionProgress;
    final active = _activeRoutine;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _DeviceCard(),
        const SizedBox(height: 20),
        Text('기기 상태', style: Theme.of(context).textTheme.titleLarge),
        // 실제 동기화 이력이 없어서(BLE 미연동) 고정 문구를 쓴다. GATT 스펙이
        // 확정되면 core/ble/ble_service.dart에서 마지막 동기화 시각을 받아와
        // 이 자리에 채워 넣으면 된다.
        const Text('동기화 기록 없음'),
        const SizedBox(height: 12),
        const _StatusCard(icon: Icons.place_outlined, label: '위치', value: '위치 정보 없음'),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: _StatusCard(icon: Icons.battery_full, label: '배터리', value: '-')),
            SizedBox(width: 12),
            Expanded(child: _StatusCard(icon: Icons.wifi, label: '와이파이', value: '연결 안 됨')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatusCard(icon: Icons.checklist, label: '미션 진행률', value: '$done/$total')),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                icon: Icons.notifications_active_outlined,
                label: '알림 재전송',
                value: '전송하기',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('워치 연동 후 사용할 수 있어요')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatusCard(
          icon: Icons.directions_walk,
          label: '현재 루틴',
          value: active == null ? '진행 중인 루틴이 없어요' : '${active.title} 진행중',
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('내 기기', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, size: 16),
                const Spacer(),
                // 실제 페어링 상태를 추적하는 곳이 아직 없어서(워치 BLE 상시 연결
                // 감지는 GATT 연동 이후 과제) 고정으로 오프라인을 보여준다.
                const Icon(Icons.circle, size: 8, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('오프라인'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.watch, size: 48),
            ),
            const SizedBox(height: 12),
            const Text('내 기기'),
            Text('TM-01', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.label, required this.value, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
