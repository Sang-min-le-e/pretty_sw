import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/routine_providers.dart';
import '../domain/big_routine.dart';
import 'big_routine_form_sheet.dart';
import 'small_routine_editor_sheet.dart';

/// Figma "루틴 등록창" — 캘린더에서 고른 [date] 하루에 대한 빅루틴 목록을 보여주고,
/// 새 빅루틴을 만들거나 기존 빅루틴을 눌러 스몰루틴을 편집할 수 있는 화면.
class RoutineRegistrationScreen extends ConsumerWidget {
  const RoutineRegistrationScreen({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(bigRoutinesForDateProvider(date));

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(date))),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return const Center(child: Text('이 날짜에 등록된 빅루틴이 없어요'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            itemBuilder: (context, index) => _BigRoutineTile(routine: routines[index], date: date),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('불러오기 실패: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBigRoutineFormSheet(context, initialDate: date),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BigRoutineTile extends ConsumerWidget {
  const _BigRoutineTile({required this.routine, required this.date});

  final BigRoutine routine;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        onTap: () => showSmallRoutineEditorSheet(
          context,
          date: date,
          routineId: routine.id,
        ),
        title: Text(routine.title),
        subtitle: Text(
          '${routine.startTime.format(context)} ~ ${routine.endTime.format(context)}'
          ' · 스몰루틴 ${routine.smallRoutines.length}개'
          ' · ${(routine.completionRate * 100).round()}% 완료',
        ),
        leading: routine.isFixedDefault ? const Icon(Icons.push_pin) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => ref.read(routineActionsProvider).deleteBigRoutine(routine),
        ),
      ),
    );
  }
}
