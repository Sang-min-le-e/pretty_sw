import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../../app/widgets/progress_ring.dart';
import '../domain/routine.dart';

/// Figma: 예소 / "3. 단일루틴 상세보기" (node-id 392:2096, "앱 초안 3" 프레임
/// 안). "오늘 할 일" 목록에서 루틴 카드를 누르면 도착한다.
///
/// 이 루틴의 하위 할 일 중 몇 개가 끝났는지를 원형 진행률 + 완료/미완료 할 일
/// 목록으로 보여준다. 완료 처리는 아이의 기기가 서버에 올리는 값이라 앱에서는
/// 읽기만 한다. 서버 모델에는 "누가 했는지"(참여자)가 없어서, 예전의 구성원별
/// 아바타 목록은 없어졌다.
///
/// 루틴은 목록 화면이 이미 받아 둔 것을 [routine]으로 넘겨받는다(라우터의
/// `state.extra`). 주소로 바로 들어오는 등 넘겨받지 못하면 안내만 보여준다.
class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({super.key, required this.routine});

  final Routine? routine;

  static const _bg = Color(0xFFF4F4F4);
  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context) {
    final routine = this.routine;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: routine == null
            // extra 없이 들어왔을 때를 대비한 방어적 처리. 실제 사용 흐름에서는
            // 항상 목록의 카드를 눌러 들어오기 때문에 거의 발생하지 않는다.
            ? const Center(child: Text('루틴을 찾을 수 없어요'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                      child: _DetailHeader(onBack: () => context.pop()),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 19),
                      child: _ProgressCard(routine: routine),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 37),
                      child: _StepSection(
                        label: '완료',
                        steps: routine.smallRoutines.where((s) => s.done).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 37),
                      child: _StepSection(
                        label: '미완료',
                        steps: routine.smallRoutines.where((s) => !s.done).toList(),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

/// 뒤로가기 화살표 + "오늘 할 일" 제목. (예전에는 오른쪽에 이 루틴을 수정하는
/// 톱니바퀴가 있었지만, 수정은 서버 규칙에 맞춰 다시 만들 때까지 뺐다.)
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkResponse(
          onTap: onBack,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(8),
            // 원본 화살표(home_chevron_prev)는 위쪽(^)을 가리키는 모양이라,
            // 왼쪽(‹)을 가리키게 하려면 반시계 방향으로 90도 돌려야 한다 —
            // 루틴 화면의 월 이동 화살표와 같은 방식.
            child: RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                'assets/images/home_chevron_prev.svg',
                width: 14,
                height: 8,
                colorFilter: const ColorFilter.mode(
                  RoutineDetailScreen._labelColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '오늘 할 일',
          style: TextStyle(
            color: RoutineDetailScreen._labelColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 흰 카드: 루틴 제목 + 시간 + 원형 진행률(완료한 할 일 비율, 가운데 "N%") +
/// 아래쪽에 "완료한 할 일 수/전체 할 일 수" 큰 숫자.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final total = routine.totalCount;
    final completed = routine.doneCount;
    final ratio = total == 0 ? 0.0 : completed / total;
    final percent = (ratio * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 19),
      child: Column(
        children: [
          Text(
            routine.title,
            style: const TextStyle(
              color: RoutineDetailScreen._labelColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (routine.timeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              routine.timeLabel,
              style: const TextStyle(color: Color(0xFF7F7F7F), fontSize: 14),
            ),
          ],
          const SizedBox(height: 28),
          ProgressRing(
            ratio: ratio,
            center: Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 44,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$completed/$total',
            style: const TextStyle(
              color: Color(0xFF868686),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// "완료" 또는 "미완료" 구역 하나: 소제목 + 그 상태인 할 일 칩들을 줄바꿈하며
/// 나열한다. 해당하는 할 일이 없으면(예: 아직 끝낸 게 없음) 구역 자체를
/// 그리지 않는다.
class _StepSection extends StatelessWidget {
  const _StepSection({required this.label, required this.steps});

  final String label;
  final List<SmallRoutine> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RoutineDetailScreen._labelColor,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final step in steps) _StepChip(title: step.title)],
        ),
      ],
    );
  }
}

/// 할 일 하나를 나타내는 흰 칩(이름만).
class _StepChip extends StatelessWidget {
  const _StepChip({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(color: RoutineDetailScreen._labelColor, fontSize: 14),
      ),
    );
  }
}
