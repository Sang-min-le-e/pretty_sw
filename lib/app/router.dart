import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/child_info_screen.dart';
import '../features/onboarding/presentation/device_connection_screen.dart';
import '../features/onboarding/presentation/guardian_info_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/routine/presentation/routine_screen.dart';
import '../features/routine/presentation/today_routines_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/watch_connection/presentation/watch_connection_screen.dart';

// 앱 전체의 화면 이동 경로(라우트) 목록.
// go_router는 "URL 경로 문자열" <-> "화면 위젯"을 1:1로 매칭해두고,
// 코드 어디서든 context.go('/경로') 또는 context.push('/경로')만 호출하면
// 해당 위젯으로 화면이 바뀌도록 해주는 라이브러리다.
final appRouter = GoRouter(
  // 앱을 처음 켰을 때 가장 먼저 보여줄 경로. 스플래시 화면이 잠깐 뜬 뒤
  // splash_screen.dart 안의 타이머가 자동으로 '/login'으로 이동시킨다.
  initialLocation: '/splash',
  routes: [
    // 1) 시작 화면 (로고만 잠깐 보여주는 스플래시)
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

    // 2) 로그인 화면 (이메일/비밀번호)
    //    로그인 성공 시 login_screen.dart의 _submit()에서
    //    - 보호자 정보가 이미 저장돼 있으면 '/' (홈)로,
    //    - 없으면(최초 로그인) '/onboarding/guardian-info'로 보낸다.
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // 3) 초기 설정(온보딩) 3단계 — 최초 로그인일 때만 순서대로 지나간다.
    GoRoute(
      path: '/onboarding/guardian-info', // 1/3: 보호자 정보 입력
      builder: (context, state) => const GuardianInfoScreen(),
    ),
    GoRoute(
      path: '/onboarding/child-info', // 2/3: 자녀 정보 입력
      builder: (context, state) => const ChildInfoScreen(),
    ),
    GoRoute(
      path: '/onboarding/device-connection', // 3/3: 기기 연결 대기 화면
      builder: (context, state) => const DeviceConnectionScreen(),
    ),

    // 4) 하단 탭바로 이동하는 4개의 메인 화면.
    //    하단 탭바(BottomNavBar)는 lib/app/widgets/bottom_nav_bar.dart에
    //    공통 위젯으로 있고, 이 4개 화면이 전부 그 위젯을 가져다 쓴다.
    GoRoute(
      path: '/', // 홈 탭 — 내 기기 상태 / 위치·와이파이 / 현재 루틴
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/routine', // 루틴(달력) 탭
      builder: (context, state) => const RoutineScreen(),
      routes: [
        // '/routine' 화면 목록 맨 아래를 더 당기면(overscroll) push로
        // 들어오는 하위 화면. 중첩 라우트로 등록해 둬야 뒤로가기 한
        // 번으로 항상 '/routine'으로 돌아간다.
        //
        // builder 대신 pageBuilder + NoTransitionPage를 쓰는 이유: 기본
        // builder는 화면을 MaterialPage로 감싸서 밀고 들어오는 슬라이드
        // 전환 애니메이션(약 300ms)을 붙이는데, 이 화면은 "새 화면으로
        // 이동"이 아니라 "스크롤해서 이어지는 내용을 보여주는" 컨셉이라
        // 그 전환 애니메이션이 오히려 화살표를 누르거나 위로 스크롤했을
        // 때 "바로 안 돌아가고 딜레이가 있다"처럼 느껴지게 만든다.
        // NoTransitionPage는 그 애니메이션 없이 즉시 화면을 바꾼다.
        // key: state.pageKey는 go_router가 내부적으로 관리하는 Navigator의
        // Page 목록에서 이 페이지를 다른 매치와 구분하기 위한 표준 관례다.
        GoRoute(
          path: 'today', // => '/routine/today', 오늘 할 일 전체 목록
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TodayRoutinesScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/devices', // 기기 탭 — 아직 자리만 잡아둔 화면
      builder: (context, state) => const DevicesScreen(),
    ),
    GoRoute(
      path: '/profile', // 내 정보(사람) 탭 — 아직 자리만 잡아둔 화면
      builder: (context, state) => const ProfileScreen(),
    ),

    // 5) 하단 탭바에는 없지만 다른 화면에서 진입할 수 있는 화면들
    GoRoute(
      path: '/watch-connection', // 워치(손목 기기) BLE 페어링 화면
      builder: (context, state) => const WatchConnectionScreen(),
    ),
  ],
);
