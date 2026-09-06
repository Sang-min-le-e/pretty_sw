import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Figma: 예소 / 홈화면의 하단 탭바 (component "Group 194", node-id 288:1926) — 4개
/// 화면(홈/루틴/기기/내 정보)이 전부 이 위젯을 가져다 써서 하단 탭바를 공유한다.
///
/// 원본 디자인에서는 "홈" 탭은 원형 배경에, 나머지 세 탭(루틴/기기/내 정보)은 하나의
/// 긴 캡슐 배경 안에 묶여 있고, 활성 탭 아이콘만 파란색으로 칠해진다. 이 그룹핑은
/// 활성 탭이 무엇이든 항상 동일하게 유지된다.
///
/// 사용하는 화면 쪽에서는 Scaffold의 bottomNavigationBar 자리에
/// `BottomNavBar(currentIndex: 0)` 처럼 "지금 이 화면이 몇 번째 탭인지"만
/// 넘겨주면 된다. (0=홈, 1=루틴, 2=기기, 3=내 정보)
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});

  /// 지금 떠 있는 화면이 어느 탭에 해당하는지. 이 인덱스에 맞는 아이콘만
  /// 파란색(활성)으로 칠해지고, 나머지는 회색(비활성)으로 보인다.
  final int currentIndex;

  // 탭 인덱스(0~3) 순서에 맞춘 이동 경로. router.dart에 등록된 경로와 반드시
  // 같은 순서·같은 문자열이어야 한다.
  static const _routes = ['/', '/routine', '/devices', '/profile'];

  // 아이콘 색상: 비활성일 때 회색, 활성일 때 브랜드 블루.
  static const _inactiveColor = Color(0xFFD9D9D9);
  static const _brandBlue = Color(0xFF4ABEFF);

  // 탭바 뒤에 깔리는 반투명 흰색 알약(pill) 모양 배경 색.
  static const _pillColor = Color(0xA3FFFFFF);

  /// 탭을 눌렀을 때 호출된다. 이미 보고 있는 탭을 다시 누르면 아무 것도
  /// 하지 않고(같은 화면으로 또 이동할 필요 없음), 다른 탭이면 go_router로
  /// 해당 경로로 이동한다.
  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // 홈 화면 배경색과 맞춰서, 탭바 주변에 비치는 여백이 이질감 없게 한다.
      color: const Color(0xFFF4F4F4),
      child: SafeArea(
        // 위쪽 SafeArea는 필요 없음(탭바는 화면 맨 아래에 있으니까).
        // 아래쪽만 켜서 기기의 하단 제스처 바(홈 인디케이터)를 피해서 그린다.
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            // 왼쪽엔 홈 아이콘(원형 배경), 오른쪽엔 나머지 3개 아이콘
            // (긴 캡슐 배경)을 두고, 그 사이는 자동으로 벌어지게 한다.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HomePill(
                active: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
              _GroupPill(
                currentIndex: currentIndex,
                onTap: (index) => _onTap(context, index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "홈" 탭 하나만 담는 동그란 배경. 원본 Figma 디자인에서 홈 아이콘만 다른
/// 3개 아이콘과 분리된 원형 캡슐 안에 따로 들어있어서 별도 위젯으로 뺐다.
class _HomePill extends StatelessWidget {
  const _HomePill({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 59,
      height: 59,
      decoration: const BoxDecoration(
        color: BottomNavBar._pillColor,
        shape: BoxShape.circle, // 정원(正圓) 모양 배경
      ),
      child: _NavIconButton(
        asset: 'assets/images/home_nav_home.svg',
        width: 27,
        height: 30,
        active: active,
        onTap: onTap,
      ),
    );
  }
}

/// "루틴 · 기기 · 내 정보" 3개 탭을 한 줄에 담는 긴 알약(캡슐) 모양 배경.
class _GroupPill extends StatelessWidget {
  const _GroupPill({required this.currentIndex, required this.onTap});

  final int currentIndex;

  /// 부모(BottomNavBar)가 넘겨준 탭 전환 콜백. 몇 번째 아이콘을 눌렀는지만
  /// 알려주면 부모 쪽에서 실제 이동 로직을 처리한다.
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 207,
      height: 59,
      decoration: BoxDecoration(
        color: BottomNavBar._pillColor,
        // 높이(59)의 절반보다 크게 줘서 양쪽 끝이 완전히 둥근 알약 모양이
        // 되도록 한다.
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        // 3개 아이콘을 캡슐 안에서 균등한 간격으로 배치한다.
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1번 탭: 루틴(달력) 화면
          _NavIconButton(
            asset: 'assets/images/home_nav_calendar.svg',
            width: 27,
            height: 31,
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // 2번 탭: 기기 화면
          _NavIconButton(
            asset: 'assets/images/home_nav_device.svg',
            width: 28,
            height: 28,
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          // 3번 탭: 내 정보(프로필) 화면
          _NavIconButton(
            asset: 'assets/images/home_nav_person.svg',
            width: 28,
            height: 28,
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

/// 탭바 아이콘 하나 + 탭 영역을 합친 버튼.
///
/// 아이콘 SVG 파일 자체는 원래 회색(#D9D9D9)으로 그려져 있는데,
/// [SvgPicture.asset]의 `colorFilter`로 그 색을 통째로 덮어씌워서
/// 활성(파란색) / 비활성(회색) 상태를 표현한다 — 즉 아이콘 파일을 2벌
/// 만들 필요 없이, 하나의 회색 아이콘을 상황에 따라 다시 칠하는 방식이다.
class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.asset,
    required this.width,
    required this.height,
    required this.active,
    required this.onTap,
  });

  final String asset;
  final double width;
  final double height;

  /// true면 이 아이콘이 지금 선택된 탭이라는 뜻.
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      // 탭 영역을 아이콘보다 넉넉하게 잡아서(radius: 28) 손가락으로 누르기
      // 쉽게 하고, 누르면 옅은 물결 효과(ripple)가 보이게 한다.
      onTap: onTap,
      radius: 28,
      child: Container(
        padding: const EdgeInsets.all(10),
        // 활성 탭에는 아이콘 뒤에 아주 옅은 회색 알약 배경을 깔아서
        // "지금 여기 눌려있다"는 느낌을 준다. 비활성이면 배경 없음(null).
        decoration: active
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              )
            : null,
        child: SvgPicture.asset(
          asset,
          width: width,
          height: height,
          // srcIn: 이 아이콘의 불투명한 부분을 전부 지정한 색 하나로
          // 덮어 칠한다(원래 아이콘 색이 무엇이든 상관없이 실루엣만 사용).
          colorFilter: ColorFilter.mode(
            active ? BottomNavBar._brandBlue : BottomNavBar._inactiveColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
