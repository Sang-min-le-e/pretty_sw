import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 하단 탭바(홈/캘린더/알림/프로필)를 담당하는 쉘 위젯.
///
/// 피그마 목업의 모든 "오늘 할 일"/"홈"/"프로필" 화면 하단에 똑같은 4개 아이콘
/// 탭바가 고정으로 붙어있길래, go_router의 `StatefulShellRoute.indexedStack`으로
/// 구현했다. 이게 일반 `ShellRoute`와 다른 점: 탭을 4개 두면 탭마다 "자기만의
/// 화면 스택"을 따로 기억한다 — 예를 들어 캘린더 탭에서 날짜를 눌러 상세 화면까지
/// 들어간 상태에서 홈 탭을 눌렀다가 다시 캘린더 탭으로 돌아오면, 방금 봤던 날짜
/// 상세 화면이 그대로 남아있다(일반 Navigator라면 캘린더 탭 첫 화면으로 리셋됨).
class RootShell extends StatelessWidget {
  const RootShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // goBranch: 탭을 눌렀을 때 그 탭의 저장된 화면 스택으로 이동한다.
        // index가 지금 보고 있는 탭과 같으면(같은 탭을 다시 눌렀으면) 그 탭의
        // 스택을 처음 화면까지 초기화해준다 — 하단 탭 UX의 표준적인 동작이다.
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '알림',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
