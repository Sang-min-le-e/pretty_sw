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

/// 루틴의 **하위 할 일**을 추가·이름 변경·삭제·순서 변경하는 화면. 상세 화면의
/// 톱니바퀴 메뉴("할 일 편집")에서 열린다.
///
/// 각 동작이 눌리는 즉시 서버에 반영된다(저장 버튼이 없다). 서버가 바꾸는
/// 범위가 동작마다 달라서 화면에 안내한다:
/// - **추가**: 이 날짜만 / 같은 반복 전체(오늘 이후)를 고른다.
/// - **이름 변경·삭제·순서 변경**: 서버에 범위 선택이 없어서 **이 날짜의 이
///   루틴에만** 적용된다.
///
/// 지난 날짜의 루틴은 편집을 막는다. 서버는 막지 않지만, 할 일 개수가 바뀌면 그
/// 날의 이행률(분모)이 달라져 이미 지나간 성적이 바뀌기 때문이다(`docs/API.md` 9장).
class RoutineStepsScreen extends ConsumerStatefulWidget {
  const RoutineStepsScreen({super.key, required this.routine});

  /// 처음 열 때 받은 루틴. 편집 결과는 달력 캐시에서 다시 읽어 최신 값을 보여준다.
  final Routine? routine;

  @override
  ConsumerState<RoutineStepsScreen> createState() => _RoutineStepsScreenState();
}

class _RoutineStepsScreenState extends ConsumerState<RoutineStepsScreen> {
  final _newStepController = TextEditingController();

  /// 서버 호출이 진행 중인지. 진행 중에는 다른 편집을 막아 요청이 겹치지 않게 한다.
  bool _busy = false;

  @override
  void dispose() {
    _newStepController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 서버 호출 하나를 감싸서 진행 표시와 오류 알림을 한 곳에서 처리한다.
  Future<bool> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(Routine routine) async {
    final title = _newStepController.text.trim();
    if (title.isEmpty) return;
    // 추가는 서버가 범위를 고르게 해 준다. 서버 기본값은 같은 반복 전체.
    final scope = await showScopeDialog(
      context,
      title: '어디에 추가할까요?',
      description: '같은 반복 전체를 고르면 오늘 이후 날짜의 같은 루틴에도 이 할 일이 생겨요.',
      defaultScope: ChangeScope.series,
    );
    if (scope == null) return;
    final ok = await _run(
      () => ref.read(routineActionsProvider).addSmallRoutine(routine, title, scope: scope),
    );
    if (ok) _newStepController.clear();
  }

  Future<void> _rename(SmallRoutine step) async {
    final controller = TextEditingController(text: step.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 이름 바꾸기'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || newTitle.isEmpty || newTitle == step.title) return;
    await _run(() => ref.read(routineActionsProvider).renameSmallRoutine(step, newTitle));
  }

  Future<void> _delete(SmallRoutine step) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일을 지울까요?'),
        content: Text("'${step.title}'을(를) 이 날짜의 루틴에서 지워요."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('지우기', style: TextStyle(color: Color(0xFFE71A1A))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => ref.read(routineActionsProvider).deleteSmallRoutine(step));
  }

  Future<void> _reorder(Routine routine, int oldIndex, int newIndex) async {
    // onReorderItem이 주는 newIndex는 이미 "빼고 난 뒤 기준"이라 그대로 넣으면 된다.
    if (newIndex == oldIndex) return;
    final steps = [...routine.smallRoutines];
    final moved = steps.removeAt(oldIndex);
    steps.insert(newIndex, moved);
    await _run(() => ref.read(routineActionsProvider).reorderSmallRoutines(routine, steps));
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.routine;
    // 편집할 때마다 달력 캐시가 갱신되므로, 같은 날짜의 같은 id 루틴을 다시 찾아
    // 최신 할 일 목록을 보여준다(못 찾으면 처음 받은 값).
    final routine = initial == null
        ? null
        : ref
                  .watch(routinesForDateProvider(initial.date))
                  .where((r) => r.id == initial.id)
                  .firstOrNull ??
              initial;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final editable = routine != null && !routine.date.isBefore(today);

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
                    BackHeader(title: '할 일 편집', onBack: () => context.pop()),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        editable
                            ? "'${routine.title}'의 할 일이에요. 이름 변경·삭제·순서 변경은 "
                                '이 날짜에만 적용되고, 추가는 같은 반복 전체에도 할 수 있어요.'
                            : '지난 날짜의 할 일은 바꿀 수 없어요. 지난 기록이 달라지지 않게 하기 위해서예요.',
                        style: const TextStyle(color: Color(0xFF7F7F7F), fontSize: 12, height: 1.5),
                      ),
                    ),
                    Expanded(
                      child: routine.smallRoutines.isEmpty
                          ? const Center(
                              child: Text(
                                '할 일이 없어요',
                                style: TextStyle(color: Color(0xFF7F7F7F), fontSize: 14),
                              ),
                            )
                          : ReorderableListView.builder(
                              // 편집할 수 없을 때(지난 날짜)는 끌기 손잡이를 아예 안 만든다.
                              buildDefaultDragHandles: false,
                              itemCount: routine.smallRoutines.length,
                              onReorderItem: (oldIndex, newIndex) {
                                if (editable && !_busy) _reorder(routine, oldIndex, newIndex);
                              },
                              itemBuilder: (context, index) {
                                final step = routine.smallRoutines[index];
                                return _StepRow(
                                  // 끌어서 옮길 때 어떤 줄인지 구분하는 키(할 일 id).
                                  key: ValueKey(step.id),
                                  index: index,
                                  step: step,
                                  editable: editable && !_busy,
                                  onRename: () => _rename(step),
                                  onDelete: () => _delete(step),
                                );
                              },
                            ),
                    ),
                    if (editable) ...[
                      const SizedBox(height: 8),
                      PillField(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newStepController,
                                style: const TextStyle(color: kRoutineFormLabelColor, fontSize: 16),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '할 일을 입력하세요....',
                                  hintStyle: TextStyle(
                                    color: kRoutineFormPlaceholderColor,
                                    fontSize: 16,
                                  ),
                                ),
                                onSubmitted: _busy ? null : (_) => _add(routine),
                              ),
                            ),
                            InkResponse(
                              onTap: _busy ? null : () => _add(routine),
                              radius: 16,
                              child: Icon(
                                Icons.add,
                                color: _busy ? kRoutineFormPlaceholderColor : const Color(0xFF4ABEFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

/// 할 일 한 줄: 끌기 손잡이 + 번호 배지 + 이름(누르면 이름 변경) + 삭제 아이콘.
/// 편집할 수 없으면(지난 날짜, 서버 호출 중) 손잡이·삭제·이름 변경이 꺼진다.
class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.step,
    required this.editable,
    required this.onRename,
    required this.onDelete,
  });

  final int index;
  final SmallRoutine step;
  final bool editable;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (editable)
            // 이 손잡이를 끌어야 순서가 바뀐다(줄 전체를 길게 눌러 끄는 기본 동작은 껐다).
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: kRoutineFormPlaceholderColor),
            )
          else
            const SizedBox(width: 24),
          const SizedBox(width: 10),
          Container(
            width: 14,
            height: 13,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: step.done ? const Color(0xFF4ABEFF) : const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: editable ? onRename : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  step.title,
                  style: const TextStyle(color: kRoutineFormLabelColor, fontSize: 15),
                ),
              ),
            ),
          ),
          if (editable)
            InkResponse(
              onTap: onDelete,
              radius: 18,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 18, color: kRoutineFormPlaceholderColor),
              ),
            ),
        ],
      ),
    );
  }
}
