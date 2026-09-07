import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 루틴 관련 화면(달력 화면, "오늘 할 일" 화면)에서 공통으로 쓰는 "+"
/// 버튼의 화면 상 고정 위치. 두 화면 모두 `Positioned(right:
/// kAddRoutineButtonRight, bottom: kAddRoutineButtonBottom, child:
/// AddRoutineButton())`처럼 똑같이 써야, 화면을 오가도 버튼이 같은
/// 자리에 그대로 떠 있는 것처럼 보인다.
const kAddRoutineButtonRight = 19.0;
const kAddRoutineButtonBottom = 24.0;

/// 화면 오른쪽 아래에 고정된 "+" 버튼. 새 루틴을 추가하는 흐름은 아직
/// 없어서 지금은 눌러도 아무 일도 일어나지 않는다(다음 작업에서 연결
/// 예정) — 그래서 onTap이 빈 콜백이다.
class AddRoutineButton extends StatelessWidget {
  const AddRoutineButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {},
      radius: 39,
      child: SvgPicture.asset(
        'assets/images/routine_add_fab.svg',
        width: 78,
        height: 78,
      ),
    );
  }
}
