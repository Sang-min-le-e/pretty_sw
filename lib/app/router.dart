import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/child_info_screen.dart';
import '../features/onboarding/presentation/device_pairing_screen.dart';
import '../features/onboarding/presentation/guardian_info_screen.dart';
import '../features/onboarding/presentation/social_login_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/routine/presentation/calendar_screen.dart';
import '../features/routine/presentation/day_routine_screen.dart';
import '../features/routine/presentation/home_screen.dart';
import '../features/watch_connection/presentation/watch_connection_screen.dart';
import 'root_shell.dart';

/// 라우트 구조는 크게 두 부류로 나뉜다.
///
/// 1) 온보딩(`/onboarding/*`)과 워치 재연결(`/watch-connection`)은 하단 탭바가
///    없는 "전체 화면" 흐름이라 `StatefulShellRoute` 바깥의 평범한 `GoRoute`로 둔다.
/// 2) 홈/캘린더/알림/프로필은 목업에서 하단 탭바가 항상 붙어있던 4개 화면이라
///    `StatefulShellRoute.indexedStack`으로 묶었다. `RootShell`(app/root_shell.dart)이
///    이 4개를 감싸는 `Scaffold`+`NavigationBar` 역할을 한다.
GoRoute _onboardingRoute(String path, Widget Function(BuildContext, GoRouterState) builder) {
  return GoRoute(path: path, builder: builder);
}

GoRouter buildAppRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      _onboardingRoute('/onboarding/social-login', (context, state) => const SocialLoginScreen()),
      _onboardingRoute('/onboarding/guardian-info', (context, state) => const GuardianInfoScreen()),
      _onboardingRoute('/onboarding/child-info', (context, state) => const ChildInfoScreen()),
      _onboardingRoute('/onboarding/device-pairing', (context, state) => const DevicePairingScreen()),
      GoRoute(path: '/watch-connection', builder: (context, state) => const WatchConnectionScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RootShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
                routes: [
                  GoRoute(
                    path: ':date',
                    builder: (context, state) {
                      // CalendarScreen이 yyyy-MM-dd 형식으로 만들어 넘겨준 문자열을
                      // 다시 DateTime으로 되돌린다. 이 형식 약속이 깨지면 여기서
                      // 바로 예외가 나서 실수를 빨리 알아챌 수 있다.
                      final date = DateTime.parse(state.pathParameters['date']!);
                      return DayRoutineScreen(date: date);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
}
