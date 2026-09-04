import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/data/character_providers.dart';
import '../data/routine_providers.dart';
import '../domain/big_routine.dart';

/// "루틴 등록창: 빅루틴 클릭 시 팝업으로 스몰루틴 작성 칸".
///
/// 스몰루틴은 "빅루틴 내부 할 일. 시간 작성 X. 연속적인 할 일"이라고 기획에
/// 적혀 있었다 — 그래서 이 화면엔 시간 입력 필드가 없고, 대신 순서(번호)가
/// 눈에 보이게 리스트로 나열된다. 체크박스를 누르면 완료 처리가 되면서
/// "미션 성공 -> 캐릭터 성장"이라는 기획 컨셉을 그대로 반영해 캐릭터에게
/// 먹이를 준다.
Future<void> showSmallRoutineEditorSheet(
  BuildContext context, {
  required DateTime date,
  required String routineId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SmallRoutineEditorSheet(date: date, routineId: routineId),
  );
}

class _SmallRoutineEditorSheet extends ConsumerStatefulWidget {
  const _SmallRoutineEditorSheet({required this.date, required this.routineId});

  final DateTime date;
  final String routineId;

  @override
  ConsumerState<_SmallRoutineEditorSheet> createState() => _SmallRoutineEditorSheetState();
}

class _SmallRoutineEditorSheetState extends ConsumerState<_SmallRoutineEditorSheet> {
  final _newTitleController = TextEditingController();

  @override
  void dispose() {
    _newTitleController.dispose();
    super.dispose();
  }

  Future<void> _addSmallRoutine(BigRoutine routine) async {
    final title = _newTitleController.text.trim();
    if (title.isEmpty) return;
    await ref.read(routineActionsProvider).addSmallRoutine(routine, title);
    _newTitleController.clear();
  }

  Future<void> _toggleDone(BigRoutine routine, String smallId) async {
    final target = routine.smallRoutines.firstWhere((s) => s.id == smallId);
    final willBeDone = !target.isDone;
    await ref.read(routineActionsProvider).toggleSmallRoutineDone(routine, target);
    // 체크를 "켤 때만" 먹이를 준다 — 실수로 체크했다 풀었다 하는 걸로
    // 캐릭터가 계속 자라나 버리면 보상의 의미가 없어지기 때문이다.
    if (willBeDone) {
      await ref.read(characterActionsProvider).feed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // routineId로 최신 상태를 다시 찾는 이유는 routine_registration_screen.dart의
    // 주석에 적어둔 것과 같다: 이 시트가 열려 있는 동안 스몰루틴을 추가/삭제/체크할
    // 때마다 provider가 invalidate되므로, 매번 최신 BigRoutine을 다시 구독해야
    // 화면이 그 변화를 반영한다.
    final routinesAsync = ref.watch(bigRoutinesForDateProvider(widget.date));

    return routinesAsync.when(
      data: (routines) {
        BigRoutine? routine;
        for (final r in routines) {
          if (r.id == widget.routineId) {
            routine = r;
            break;
          }
        }
        if (routine == null) {
          // 마지막 스몰루틴을 지워서 빅루틴 자체가 삭제된 경우 등 — 그냥 닫아버린다.
          return const SizedBox.shrink();
        }
        return _buildContent(context, routine);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text('불러오기 실패: $error'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BigRoutine routine) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sorted = [...routine.smallRoutines]..sort((a, b) => a.order.compareTo(b.order));

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(routine.title, style: Theme.of(context).textTheme.titleLarge),
          const Text('순서대로 처리할 스몰루틴이에요'),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('아직 스몰루틴이 없어요. 아래에서 추가해보세요.'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final small = sorted[index];
                  return CheckboxListTile(
                    value: small.isDone,
                    onChanged: (_) => _toggleDone(routine, small.id),
                    title: Text('${small.order + 1}. ${small.title}'),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(routineActionsProvider)
                          .deleteSmallRoutine(routine, small.id),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTitleController,
                  decoration: const InputDecoration(hintText: '예: 씻기, 약국 도착하기'),
                  onSubmitted: (_) => _addSmallRoutine(routine),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () => _addSmallRoutine(routine),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
