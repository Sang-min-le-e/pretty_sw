import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';

/// Figma: 예소 / "4. 루틴 추가 선택 화면" (node-id 392:2016, "앱 초안 3" 프레임
/// 안). 루틴 화면들의 "+" 버튼을 누르면 도착하는, "무엇을 추가할지" 고르는
/// 중간 화면이다.
///
/// 세 가지 선택지 전부 실제 화면으로 연결돼 있다: "단일/복합 루틴
/// 추가하기"는 같은 [AddRoutineScreen]을 `compound` 플래그만 다르게 열고,
/// "템플릿 사용"은 저장된 템플릿 목록 화면으로 이동한다.
class RoutineTypeSelectScreen extends StatelessWidget {
  const RoutineTypeSelectScreen({super.key});

  static const _bg = Color(0xFFF4F4F4);
  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
              child: Row(
                children: [
                  InkResponse(
                    onTap: () => context.pop(),
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SvgPicture.asset(
                          'assets/images/home_chevron_prev.svg',
                          width: 14,
                          height: 8,
                          colorFilter: const ColorFilter.mode(
                            _labelColor,
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
                      color: _labelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 33),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Column(
                children: [
                  _TypeOption(
                    icon: 'assets/images/routine_calendar_plus.svg',
                    label: '단일 루틴 추가하기',
                    onTap: () => context.push('/routine/add/single'),
                  ),
                  const SizedBox(height: 9),
                  _TypeOption(
                    icon: 'assets/images/routine_calendar_plus.svg',
                    label: '복합 루틴 추가하기',
                    onTap: () => context.push('/routine/add/compound'),
                  ),
                  const SizedBox(height: 9),
                  _TypeOption(
                    icon: 'assets/images/routine_calendar_check.svg',
                    label: '템플릿 사용',
                    onTap: () => context.push('/routine/add/templates'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

/// 알약 모양(radius 44) 선택지 카드 한 장.
class _TypeOption extends StatelessWidget {
  const _TypeOption({required this.icon, required this.label, this.onTap});

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(44),
      child: Container(
        width: double.infinity,
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(44),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 28, height: 31, child: SvgPicture.asset(icon)),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                color: RoutineTypeSelectScreen._labelColor,
                fontSize: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
