import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/routine_providers.dart';

/// "루틴 추가" 팝업 — 목업에서 이 흐름이 **여러 단계로 나뉜 마법사(wizard)**였다.
/// 1) 제목 입력 -> 2) 시간 설정 -> 3) 알림/고정 루틴(+반복 요일) 설정 -> 완료.
/// 처음 구현에서는 이 세 가지를 한 화면에 다 몰아넣은 폼이었는데, 목업처럼
/// 한 번에 한 가지만 물어보는 방식이 이 앱의 대상 사용자(지적장애인 보호자도
/// 포함해서 누구나)에게 더 부담이 적어서 그대로 따라갔다.
Future<void> showBigRoutineFormSheet(BuildContext context, {required DateTime initialDate}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    // 이 화면은 하단 탭바(StatefulShellRoute)가 만든 "탭 전용 네비게이터" 안에서
    // 열린다. showModalBottomSheet의 기본값(useRootNavigator: false)은 그 탭
    // 네비게이터 기준으로 시트를 그려서, 화면 전체를 덮는 게 아니라 하단
    // 탭바 뒤에 가려지는 버그가 있었다. 앱 전체의 최상위 네비게이터를 쓰도록
    // 명시해야 화면 전체를 제대로 덮는다.
    useRootNavigator: true,
    builder: (context) => _BigRoutineFormSheet(initialDate: initialDate),
  );
}

enum _Step { title, time, notify }

class _BigRoutineFormSheet extends ConsumerStatefulWidget {
  const _BigRoutineFormSheet({required this.initialDate});
  final DateTime initialDate;

  @override
  ConsumerState<_BigRoutineFormSheet> createState() => _BigRoutineFormSheetState();
}

class _BigRoutineFormSheetState extends ConsumerState<_BigRoutineFormSheet> {
  _Step _step = _Step.title;
  final _titleController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isRecurring = false;
  final Set<int> _recurringWeekdays = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    switch (_step) {
      case _Step.title:
        return _titleController.text.trim().isNotEmpty;
      case _Step.time:
        return true;
      case _Step.notify:
        return true;
    }
  }

  bool _isSubmitting = false;

  void _goNext() {
    if (_step == _Step.notify) {
      // 마지막 단계에서 "완료"를 연달아 여러 번 누르면 빅루틴이 중복으로
      // 만들어질 수 있어서(비동기 저장이 끝나기 전에 또 눌리는 경우) 막아둔다.
      if (_isSubmitting) return;
      _submit();
      return;
    }
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  void _goBack() {
    if (_step == _Step.title) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step = _Step.values[_step.index - 1]);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    await ref.read(routineActionsProvider).createBigRoutine(
      title: _titleController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      date: widget.initialDate,
      isRecurring: _isRecurring,
      recurringWeekdays: _recurringWeekdays,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('루틴 추가', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          switch (_step) {
            _Step.title => _TitleStep(controller: _titleController, onChanged: () => setState(() {})),
            _Step.time => _TimeStep(
              startTime: _startTime,
              endTime: _endTime,
              onPickStart: () => _pickTime(isStart: true),
              onPickEnd: () => _pickTime(isStart: false),
            ),
            _Step.notify => _NotifyStep(
              isRecurring: _isRecurring,
              recurringWeekdays: _recurringWeekdays,
              onRecurringChanged: (value) => setState(() => _isRecurring = value),
              onWeekdayToggled: (weekday) => setState(() {
                if (_recurringWeekdays.contains(weekday)) {
                  _recurringWeekdays.remove(weekday);
                } else {
                  _recurringWeekdays.add(weekday);
                }
              }),
            ),
          },
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _goBack,
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_canGoNext && !_isSubmitting) ? _goNext : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == _Step.notify ? '완료' : '다음'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TitleStep extends StatelessWidget {
  const _TitleStep({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: const InputDecoration(labelText: '루틴 제목', hintText: '예: 아침 루틴, 병원가기'),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.startTime,
    required this.endTime,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: onPickStart, child: Text('시작 ${startTime.format(context)}')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(onPressed: onPickEnd, child: Text('종료 ${endTime.format(context)}')),
        ),
      ],
    );
  }
}

class _NotifyStep extends StatelessWidget {
  const _NotifyStep({
    required this.isRecurring,
    required this.recurringWeekdays,
    required this.onRecurringChanged,
    required this.onWeekdayToggled,
  });

  final bool isRecurring;
  final Set<int> recurringWeekdays;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<int> onWeekdayToggled;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('고정 루틴'),
          subtitle: const Text('선택한 요일마다 자동으로 반복돼요'),
          value: isRecurring,
          onChanged: onRecurringChanged,
        ),
        if (isRecurring)
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              // DateTime.weekday는 월=1 ... 일=7 이라서 라벨 순서(월~일)와 맞춰준다.
              final weekday = index + 1;
              final selected = recurringWeekdays.contains(weekday);
              return FilterChip(
                label: Text(_weekdayLabels[index]),
                selected: selected,
                onSelected: (_) => onWeekdayToggled(weekday),
              );
            }),
          ),
      ],
    );
  }
}
