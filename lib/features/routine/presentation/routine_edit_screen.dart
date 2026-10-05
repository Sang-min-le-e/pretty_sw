import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../../core/network/api_exception.dart';
import '../data/routine_providers.dart';
import '../domain/change_scope.dart';
import '../domain/routine.dart';
import 'widgets/routine_form_widgets.dart';
import 'widgets/scope_dialog.dart';

/// 루틴의 **이름과 시작·종료 시각**을 고치는 화면. 상세 화면의 톱니바퀴 메뉴
/// ("수정")에서 열린다.
///
/// 서버의 수정 API(`PATCH /big-routines/:id`)는 이 세 가지만 바꿀 수 있어서,
/// 날짜·반복·하위 할 일까지 다루는 추가 폼([AddRoutineScreen])을 재사용하지 않고
/// 화면을 따로 두었다. 하위 할 일은 `RoutineStepsScreen`에서 고친다.
///
/// "저장"을 누르면 어디까지 적용할지(이 날짜만 / 같은 반복 전체)를 묻는다 —
/// 반복으로 만든 루틴은 날짜마다 행이 따로 있기 때문이다.
class RoutineEditScreen extends ConsumerStatefulWidget {
  const RoutineEditScreen({super.key, required this.routine});

  /// 고칠 루틴. 라우터가 `state.extra`로 넘겨준다(없으면 안내만 보여준다).
  final Routine? routine;

  @override
  ConsumerState<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  late final _titleController = TextEditingController(text: widget.routine?.title ?? '');
  late TimeOfDay _startTime = parseHhmm(widget.routine?.startTime);
  late TimeOfDay _endTime = parseHhmm(widget.routine?.endTime, fallback: const TimeOfDay(hour: 0, minute: 1));
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _save(Routine routine) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('루틴 이름을 입력해 주세요');
      return;
    }
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      _showMessage('종료 시간은 시작 시간보다 뒤여야 해요');
      return;
    }

    // 어디까지 고칠지 묻는다. 수정은 되돌릴 수 있어서 서버 기본값은 같은 반복 전체.
    final scope = await showScopeDialog(
      context,
      title: '어디까지 고칠까요?',
      description: '같은 반복 전체를 고르면 오늘 이후 날짜의 같은 루틴도 함께 바뀌어요. '
          '지난 날짜의 기록은 그대로 남아요.',
      defaultScope: ChangeScope.series,
    );
    if (scope == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(routineActionsProvider).updateRoutine(
            routine,
            title: title,
            startTime: formatHhmm(_startTime),
            endTime: formatHhmm(_endTime),
            scope: scope,
          );
      if (!mounted) return;
      // 상세 화면은 달력 캐시를 보고 있어서 돌아가면 고친 값이 바로 보인다.
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.routine;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: routine == null
            ? const Center(child: Text('루틴을 찾을 수 없어요'))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    BackHeader(title: '루틴 수정하기', onBack: () => context.pop()),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '루틴 이름',
                            style: TextStyle(color: kRoutineFormLabelColor, fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          PillField(
                            child: TextField(
                              controller: _titleController,
                              style: const TextStyle(color: kRoutineFormLabelColor, fontSize: 16),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            '시간 설정',
                            style: TextStyle(color: kRoutineFormLabelColor, fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TimeField(
                                  time: _startTime,
                                  suffix: '부터',
                                  onTap: () => _pickTime(isStart: true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TimeField(
                                  time: _endTime,
                                  suffix: '까지',
                                  onTap: () => _pickTime(isStart: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '날짜와 반복은 여기서 바꿀 수 없어요. 바꾸려면 루틴을 지우고 새로 만들어 주세요.',
                            style: TextStyle(color: Color(0xFF7F7F7F), fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _save(routine),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ABEFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('저장', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}
