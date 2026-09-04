import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/routine_providers.dart';
import '../domain/big_routine.dart';

/// "행동 추가" 팝업 — 목업에서는 텍스트 입력 한 칸짜리 아주 단순한 모달이었다.
/// (처음 구현에서 만들었던 small_routine_editor_sheet.dart는 체크리스트 전체를
/// 보여주는 큰 시트였는데, 실제 목업은 체크리스트 자체는 "오늘 할 일" 화면에
/// 바로 인라인으로 보여주고, 이 팝업은 "새 행동 하나 추가하기"에만 집중한다.)
Future<void> showAddSmallRoutineSheet(BuildContext context, {required BigRoutine routine}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // big_routine_form_sheet.dart의 useRootNavigator 주석과 같은 이유.
    useRootNavigator: true,
    builder: (context) => _AddSmallRoutineSheet(routine: routine),
  );
}

class _AddSmallRoutineSheet extends ConsumerStatefulWidget {
  const _AddSmallRoutineSheet({required this.routine});
  final BigRoutine routine;

  @override
  ConsumerState<_AddSmallRoutineSheet> createState() => _AddSmallRoutineSheetState();
}

class _AddSmallRoutineSheetState extends ConsumerState<_AddSmallRoutineSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _isSubmitting = true);
    await ref.read(routineActionsProvider).addSmallRoutine(widget.routine, title);
    if (!mounted) return;
    Navigator.of(context).pop();
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
          Text('행동 추가', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '예: 씻기, 가방 싸기'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: const Text('행동 추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
