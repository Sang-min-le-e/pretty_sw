import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/routine_providers.dart';
import '../domain/big_routine.dart';
import '../domain/small_routine.dart';
import 'add_small_routine_sheet.dart';
import 'big_routine_form_sheet.dart';

/// 목업의 "오늘 할 일" 화면. 캘린더에서 날짜를 눌러 들어온다.
///
/// 처음 구현과 가장 크게 달라진 부분: 스몰루틴(행동)을 별도 팝업으로 열어서
/// 확인하게 만들지 않고, 빅루틴 카드 안에 번호 매긴 체크리스트로 바로
/// 펼쳐서 보여준다 — 목업이 그렇게 되어 있었고, 화면을 한 번 더 열어야 하는
/// 것보다 스크롤 한 번으로 오늘 할 일을 전부 볼 수 있는 쪽이 사용자에게도 낫다.
class DayRoutineScreen extends ConsumerWidget {
  const DayRoutineScreen({required this.date, super.key});

  final DateTime date;

  Future<void> _confirmSend(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전송하시겠습니까?'),
        content: const Text('한 번 전송한 루틴은 수정할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('전송하기')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(routineActionsProvider).sendRoutinesForDate(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(bigRoutinesForDateProvider(date));

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M월 d일 (E)', 'ko_KR').format(date)),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_circle_up_outlined),
            tooltip: '워치로 전송',
            onPressed: () => _confirmSend(context, ref),
          ),
        ],
      ),
      body: routinesAsync.when(
        data: (routines) => _DayBody(date: date, routines: routines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('불러오기 실패: $error')),
      ),
    );
  }
}

class _DayBody extends ConsumerWidget {
  const _DayBody({required this.date, required this.routines});

  final DateTime date;
  final List<BigRoutine> routines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSent = routines.isNotEmpty && routines.every((r) => r.isSent);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final routine in routines) ...[
          _BigRoutineCard(routine: routine),
          const SizedBox(height: 12),
        ],
        if (!allSent)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showBigRoutineFormSheet(context, initialDate: date),
                  icon: const Icon(Icons.add),
                  label: const Text('루틴 추가하기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('템플릿 기능은 곧 지원돼요'))),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('템플릿 사용'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BigRoutineCard extends ConsumerWidget {
  const _BigRoutineCard({required this.routine});
  final BigRoutine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...routine.smallRoutines]..sort((a, b) => a.order.compareTo(b.order));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${routine.title} · ${routine.startTime.format(context)}~${routine.endTime.format(context)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (routine.isSent)
                  const Tooltip(message: '전송된 루틴은 수정할 수 없어요', child: Icon(Icons.lock_outline, size: 18))
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => ref.read(routineActionsProvider).deleteBigRoutine(routine),
                  ),
              ],
            ),
            for (final small in sorted)
              _SmallRoutineRow(routine: routine, small: small),
            if (!routine.isSent)
              TextButton.icon(
                onPressed: () => showAddSmallRoutineSheet(context, routine: routine),
                icon: const Icon(Icons.add),
                label: Text(sorted.isEmpty ? '행동 추가하기' : '행동 추가'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallRoutineRow extends ConsumerWidget {
  const _SmallRoutineRow({required this.routine, required this.small});
  final BigRoutine routine;
  final SmallRoutine small;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Checkbox(
          value: small.isDone,
          onChanged: (_) => ref.read(routineActionsProvider).toggleSmallRoutineDone(routine, small),
        ),
        Expanded(
          child: Text(
            '${small.order + 1}. ${small.title}',
            style: small.isDone ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
          ),
        ),
        if (!routine.isSent)
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref.read(routineActionsProvider).deleteSmallRoutine(routine, small.id),
          ),
      ],
    );
  }
}
