import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../character/presentation/character_card.dart';
import '../data/routine_providers.dart';
import '../domain/big_routine.dart';

/// Figma "4. 내 기기 (디바이스 정보 파악) - 메인 창".
///
/// 기획 문구 그대로 옮기면: "자녀의 미션 이행률이나 기기 배터리 등 정보를 볼 수
/// 있는 창. 검사겸사 메인창." — 즉 이 화면은 앱을 켰을 때 가장 먼저 보이는
/// 대시보드이면서 동시에 "오늘 상태를 훑어보는" 용도다. 기획에 있던 3개 항목을
/// 그대로 카드로 배치했다:
///   1. 이번주 미션 이행률
///   2. 어제 미션 이행률
///   3. 마지막 동기화 시점 / 배터리 잔량
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRoutinesAsync = ref.watch(allBigRoutinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 루틴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.watch),
            tooltip: '워치 연결',
            onPressed: () => context.push('/watch-connection'),
          ),
        ],
      ),
      body: allRoutinesAsync.when(
        data: (routines) => _DashboardBody(routines: routines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('불러오기 실패: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/calendar'),
        icon: const Icon(Icons.calendar_month),
        label: const Text('루틴 관리'),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.routines});

  final List<BigRoutine> routines;

  /// 오늘 기준으로 "이번 주(월~일)"에 걸쳐 있는 빅루틴들의 평균 이행률.
  /// appliesOn()이 날짜 범위 전체를 검사하므로, 연속 날짜로 등록된 빅루틴이
  /// 이번 주 중 하루라도 걸쳐 있으면 포함시킨다.
  double _weeklyCompletionRate() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _averageRateBetween(startOfWeek, endOfWeek);
  }

  double _yesterdayCompletionRate() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _averageRateBetween(yesterday, yesterday);
  }

  double _averageRateBetween(DateTime start, DateTime end) {
    final relevant = routines.where(
      (r) => r.appliesOn(start) || r.appliesOn(end) || (r.startDate.isAfter(start) && r.startDate.isBefore(end)),
    ).toList();
    if (relevant.isEmpty) return 0;
    final total = relevant.fold<double>(0, (sum, r) => sum + r.completionRate);
    return total / relevant.length;
  }

  /// 이행률이 가장 낮은 빅루틴을 찾아서 기획서 예시 문구("OO 미션에 대해
  /// 이행률이 낮아요")처럼 알림 카드에 보여준다. 스몰루틴이 하나도 없는
  /// (=아직 아무것도 안 채운) 빅루틴은 "완료율 0%"로 잡혀서 항상 최하위가 되어버리니
  /// 알림이 의미 없어지므로 제외한다.
  BigRoutine? _lowestPerformingRoutine() {
    final withProgress = routines.where((r) => r.smallRoutines.isNotEmpty).toList();
    if (withProgress.isEmpty) return null;
    withProgress.sort((a, b) => a.completionRate.compareTo(b.completionRate));
    final lowest = withProgress.first;
    return lowest.completionRate < 0.5 ? lowest : null;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyRate = _weeklyCompletionRate();
    final yesterdayRate = _yesterdayCompletionRate();
    final alertRoutine = _lowestPerformingRoutine();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _RateCard(label: '이번주 미션 이행률', rate: weeklyRate),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RateCard(label: '어제 미션 이행률', rate: yesterdayRate),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _SyncStatusCard(),
        if (alertRoutine != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"${alertRoutine.title}" 미션에 대해 이행률이 낮아요',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const CharacterCard(),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.label, required this.rate});

  final String label;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              '${(rate * 100).round()}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// 마지막 동기화 시점 / 배터리 잔량 카드.
///
/// 아직 워치와의 GATT 통신 스펙이 정해지지 않아서 실제 배터리 값을 읽어올 방법이
/// 없다. 그래서 지금은 "동기화된 적 없음" 상태만 보여주고, 나중에
/// BleService에 배터리/동기화 시간을 읽는 캐릭터리스틱이 추가되면 이 위젯을
/// 그 값을 구독하는 Provider로 바꿔주면 된다.
class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.sync_problem_outlined),
            SizedBox(width: 12),
            Expanded(child: Text('아직 워치와 동기화된 적이 없어요. 워치를 연결해주세요.')),
          ],
        ),
      ),
    );
  }
}
