import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/routine_providers.dart';

/// "루틴 등록창: 빅루틴 생성" 팝업.
///
/// 캘린더에서 날짜를 눌러 들어온 [initialDate]를 시작일로 미리 채워둔다.
/// 기획서의 "설정값2: 날짜 선택 / 연속적 날짜 선택"을 [_repeatsAcrossDates]
/// 체크박스 하나로 표현했다 — 체크를 안 하면 시작일=종료일(하루짜리),
/// 체크하면 종료일을 따로 고를 수 있게 했다.
///
/// `showModalBottomSheet`로 띄우는 이유: 캘린더/루틴 목록 화면의 맥락(어떤 날짜를
/// 보고 있었는지)을 유지한 채로 짧은 입력만 받고 싶을 때, 화면 전체를 새로
/// 띄우는 것보다 바텀시트가 "지금 하던 걸 잠깐 확장해서 처리한다"는 느낌을 준다.
Future<void> showBigRoutineFormSheet(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BigRoutineFormSheet(initialDate: initialDate),
  );
}

class _BigRoutineFormSheet extends ConsumerStatefulWidget {
  const _BigRoutineFormSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<_BigRoutineFormSheet> createState() => _BigRoutineFormSheetState();
}

class _BigRoutineFormSheetState extends ConsumerState<_BigRoutineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  late final DateTime _startDate = widget.initialDate;
  late DateTime _endDate = widget.initialDate;
  bool _repeatsAcrossDates = false;
  bool _isFixedDefault = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(routineActionsProvider).createBigRoutine(
      title: _titleController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      startDate: _startDate,
      endDate: _repeatsAcrossDates ? _endDate : _startDate,
      isFixedDefault: _isFixedDefault,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 키보드가 올라올 때 바텀시트 내용이 가려지지 않도록 viewInsets만큼
    // 아래쪽 패딩을 더해준다 — Flutter에서 바텀시트/키보드 조합에 흔히 쓰는 패턴.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('빅루틴 만들기', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '빅루틴 제목'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: true),
                    child: Text('시작 ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: false),
                    child: Text('종료 ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('연속된 날짜에 반복 적용'),
              value: _repeatsAcrossDates,
              onChanged: (value) => setState(() => _repeatsAcrossDates = value),
            ),
            if (_repeatsAcrossDates)
              OutlinedButton(
                onPressed: _pickEndDate,
                child: Text(
                  '${DateFormat('yyyy.MM.dd').format(_startDate)} ~ '
                  '${DateFormat('yyyy.MM.dd').format(_endDate)}',
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('고정 빅루틴으로 설정'),
              subtitle: const Text('앞으로 루틴을 등록할 때 기본값으로 생성돼요'),
              value: _isFixedDefault,
              onChanged: (value) => setState(() => _isFixedDefault = value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: const Text('만들기')),
          ],
        ),
      ),
    );
  }
}
