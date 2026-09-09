import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../domain/routine.dart';

/// 루틴 카드 한 장. "11:00 교무실 가기 ・지예님의 기기" 한 줄에, 여러
/// 단계로 이뤄진 루틴([routine.steps]가 있는 경우)이면 그 아래 번호가
/// 매겨진 하위 할 일 목록이 항상(토글 없이) 펼쳐져 보인다. 오른쪽 끝의
/// 화살표(›)는 눌렀을 때 완료 현황을 보여주는 상세 화면
/// (`RoutineDetailScreen`, Figma node 392:2096)으로 이동하는 버튼이다 —
/// 이전 버전에서는 이 화살표가 "카드 접기/펼치기" 토글이었지만, 새
/// 디자인에서는 여러 단계 루틴도 목록에서 항상 펼쳐진 채로 보이고
/// 화살표는 상세 화면으로만 쓰인다.
///
/// 달력이 있는 루틴 화면(`RoutineScreen`)과 "오늘 할 일" 전체 목록 화면
/// (`TodayRoutinesScreen`)이 똑같은 카드 디자인을 쓰기 때문에, 두 화면
/// 어디서든 가져다 쓸 수 있게 공용 위젯으로 뺐다.
class RoutineCard extends StatelessWidget {
  const RoutineCard({super.key, required this.routine});

  final Routine routine;

  static const _labelColor = Color(0xFF505050);
  static const _captionColor = Color(0xFF7F7F7F);

  @override
  Widget build(BuildContext context) {
    final hasSteps = routine.steps.isNotEmpty;
    final time = TimeOfDay.fromDateTime(routine.dateTime);
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => context.push('/routine/detail/${routine.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(23, 16, 15, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$timeLabel ${routine.title}',
                        style: const TextStyle(
                          color: _labelColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '・${routine.tag}',
                        style: const TextStyle(
                          color: _captionColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    'assets/images/home_chevron_small.svg',
                    width: 7,
                    height: 4,
                  ),
                ),
              ],
            ),
            if (hasSteps) ...[
              const SizedBox(height: 14),
              for (var i = 0; i < routine.steps.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12, left: 4),
                  child: _RoutineStepRow(
                    stepNumber: i + 1,
                    title: routine.steps[i],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 펼쳐진 카드 안, 하위 할 일 한 줄: 회색 번호 배지 + 할 일 텍스트.
class _RoutineStepRow extends StatelessWidget {
  const _RoutineStepRow({required this.stepNumber, required this.title});

  final int stepNumber;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 13,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            '$stepNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Color(0xFF505050), fontSize: 15),
        ),
      ],
    );
  }
}

/// 루틴이 하나도 없을 때(아직 "+"로 아무것도 추가하지 않은 기본 상태)
/// 카드 자리에 대신 보여주는 안내 문구 카드.
class EmptyRoutineCard extends StatelessWidget {
  const EmptyRoutineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        '등록된 루틴이 없어요\n오른쪽 아래 + 버튼으로 추가해 보세요',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF7F7F7F), fontSize: 14, height: 1.5),
      ),
    );
  }
}

/// [routines]를 세로로 나열한다. 비어 있으면 [EmptyRoutineCard]를 보여준다.
class RoutineCardList extends StatelessWidget {
  const RoutineCardList({super.key, required this.routines});

  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const EmptyRoutineCard();
    }

    return Column(
      children: [
        for (final routine in routines) ...[
          RoutineCard(routine: routine),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
