import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/child_info_screen.dart';
import '../features/onboarding/presentation/device_pairing_screen.dart';
import '../features/onboarding/presentation/guardian_info_screen.dart';
import '../features/onboarding/presentation/social_login_screen.dart';
import '../features/routine/presentation/calendar_screen.dart';
import '../features/routine/presentation/dashboard_screen.dart';
import '../features/routine/presentation/routine_registration_screen.dart';
import '../features/watch_connection/presentation/watch_connection_screen.dart';

/// 라우트 구조는 Figma 기획의 화면 번호를 그대로 따라간다.
///
///  /onboarding/*        1. 초기 설정 (소셜 로그인 -> 보호자 -> 자녀 -> 페어링)
///  /                     4. 내 기기(메인창) = 대시보드
///  /calendar             루틴 등록의 시작점인 캘린더
///  /calendar/:date/routines   2. 루틴 등록 (특정 날짜의 빅/스몰루틴 관리)
///  /watch-connection     대시보드에서 언제든 다시 들어갈 수 있는 워치 재연결 화면
///
/// [initialLocation]을 함수 인자로 받는 이유: 온보딩을 이미 끝낸 사용자가
/// 앱을 다시 켰을 때는 로그인 화면부터 또 보여주면 안 되기 때문이다.
/// main.dart에서 Hive에 저장된 "온보딩 완료 여부"를 먼저 확인한 뒤, 그 결과에
/// 따라 시작 위치를 '/onboarding/social-login' 또는 '/'로 정해서 넘겨준다.
GoRouter buildAppRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding/social-login',
        builder: (context, state) => const SocialLoginScreen(),
      ),
      GoRoute(
        path: '/onboarding/guardian-info',
        builder: (context, state) => const GuardianInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding/child-info',
        builder: (context, state) => const ChildInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding/device-pairing',
        builder: (context, state) => const DevicePairingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/calendar/:date/routines',
        builder: (context, state) {
          // path param은 항상 String으로 들어오기 때문에, 화면 쪽에서 쓰기 편하도록
          // 여기서 DateTime으로 한 번 파싱해서 넘겨준다. (yyyy-MM-dd 형식 약속은
          // CalendarScreen에서 DateFormat으로 만들 때와 여기가 반드시 맞아야 한다.)
          final date = DateTime.parse(state.pathParameters['date']!);
          return RoutineRegistrationScreen(date: date);
        },
      ),
      GoRoute(
        path: '/watch-connection',
        builder: (context, state) => const WatchConnectionScreen(),
      ),
    ],
  );
}
