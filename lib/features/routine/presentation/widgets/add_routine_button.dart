import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// 루틴 관련 화면(달력 화면, "오늘 할 일" 화면)에서 공통으로 쓰는 "+"
/// 버튼의 화면 상 고정 위치. 두 화면 모두 `Positioned(right:
/// kAddRoutineButtonRight, bottom: kAddRoutineButtonBottom, child:
/// AddRoutineButton())`처럼 똑같이 써야, 화면을 오가도 버튼이 같은
/// 자리에 그대로 떠 있는 것처럼 보인다.
const kAddRoutineButtonRight = 19.0;
const kAddRoutineButtonBottom = 24.0;

/// 화면 오른쪽 아래에 고정된 "+" 버튼. 누르면 "단일 루틴 / 복합 루틴 /
/// 템플릿" 중 무엇을 추가할지 고르는 화면(`/routine/add`)으로 넘어간다.
class AddRoutineButton extends StatelessWidget {
  const AddRoutineButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => context.push('/routine/add'),
      radius: 39,
      child: SvgPicture.asset(
        'assets/images/routine_add_fab.svg',
        width: 78,
        height: 78,
      ),
    );
  }
}
