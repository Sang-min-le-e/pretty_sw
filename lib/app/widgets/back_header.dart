import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "‹ 화면 제목" 형태의 상단 바. 뒤로가기 화살표 + 제목 + (선택) 오른쪽
/// 끝에 붙는 위젯(설정 톱니바퀴 등) 하나로 구성된다 — 루틴/기기/내 정보
/// 쪽 여러 화면이 전부 이 모양을 반복해서 쓰길래 공용 위젯으로 뺐다.
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title, required this.onBack, this.trailing});

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  static const _labelColor = Color(0xFF505050);

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
            // 왼쪽(‹)을 가리키게 하려면 반시계 방향으로 90도 돌려야 한다.
            child: RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                'assets/images/home_chevron_prev.svg',
                width: 14,
                height: 8,
                colorFilter: const ColorFilter.mode(_labelColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(color: _labelColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}
