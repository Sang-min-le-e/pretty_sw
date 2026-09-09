import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/login_social_basic_info_screen.dart';
import '../features/auth/presentation/login_social_screen.dart';
import '../features/devices/presentation/add_connected_device_screen.dart';
import '../features/devices/presentation/add_device_screen.dart';
import '../features/devices/presentation/connected_devices_screen.dart';
import '../features/devices/presentation/device_detail_screen.dart';
import '../features/devices/presentation/device_settings_screen.dart';
import '../features/devices/presentation/device_stats_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/devices/presentation/wifi_settings_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/child_info_screen.dart';
import '../features/onboarding/presentation/device_connection_screen.dart';
import '../features/onboarding/presentation/guardian_info_screen.dart';
import '../features/profile/presentation/language_screen.dart';
import '../features/profile/presentation/login_history_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/user_settings_screen.dart';
import '../features/routine/domain/routine_template.dart';
import '../features/routine/presentation/add_routine_screen.dart';
import '../features/routine/presentation/routine_detail_screen.dart';
import '../features/routine/presentation/routine_screen.dart';
import '../features/routine/presentation/routine_template_list_screen.dart';
import '../features/routine/presentation/routine_type_select_screen.dart';
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
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
      routes: [
        // => '/login/social', 원래 Figma 목업이던 소셜 로그인 화면
        // (login_screen.dart 문서 주석 참고 — 실사용 로그인 수단은 아니다).
        GoRoute(
          path: 'social',
          builder: (context, state) => const LoginSocialScreen(),
          routes: [
            GoRoute(
              path: 'basic-info',
              builder: (context, state) => const LoginSocialBasicInfoScreen(),
            ),
          ],
        ),
      ],
    ),

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
        // => '/routine/detail/:id', 루틴 카드의 화살표(›)를 누르면
        // 도착하는 완료 현황 상세 화면.
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) =>
              RoutineDetailScreen(routineId: state.pathParameters['id']!),
        ),
        // => '/routine/edit/:id', 상세 화면 우측 상단 설정 톱니바퀴를
        // 누르면 도착하는 수정 폼(Figma "7"/"7-1").
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) =>
              RoutineEditScreen(routineId: state.pathParameters['id']!),
        ),
        // => '/routine/add', "+" 버튼을 누르면 도착하는 "단일 루틴 /
        // 복합 루틴" 선택 화면(Figma "4. 루틴 추가 선택 화면").
        GoRoute(
          path: 'add',
          builder: (context, state) => const RoutineTypeSelectScreen(),
          routes: [
            // => '/routine/add/single', 단일 루틴 추가 폼. "템플릿 사용"
            // 화면에서 템플릿을 골라 들어오면 state.extra로 그 템플릿을
            // 받아서 이름/할 일 목록을 미리 채운다.
            GoRoute(
              path: 'single',
              builder: (context, state) => AddRoutineScreen(
                template: state.extra as RoutineTemplate?,
              ),
            ),
            // => '/routine/add/compound', 복합 루틴 추가 폼.
            GoRoute(
              path: 'compound',
              builder: (context, state) => const AddRoutineScreen(compound: true),
            ),
            // => '/routine/add/templates', 저장된 템플릿 목록.
            GoRoute(
              path: 'templates',
              builder: (context, state) => const RoutineTemplateListScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/devices', // 기기 탭 — 등록된 자녀 기기 그리드
      builder: (context, state) => const DevicesScreen(),
      routes: [
        // => '/devices/add', "기기 추가하기" 점선 카드를 누르면 도착하는
        // BLE 페어링 대기 + WIFI 입력 2단계 화면.
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddDeviceScreen(),
        ),
        // => '/devices/:name', 기기 카드를 누르면 도착하는 상세 관리 화면.
        GoRoute(
          path: ':name',
          builder: (context, state) => DeviceDetailScreen(
            deviceOwnerName: state.pathParameters['name']!,
          ),
          routes: [
            // => '/devices/:name/wifi', 상세 화면의 "연결됨" 줄을 누르면.
            GoRoute(
              path: 'wifi',
              builder: (context, state) => const WifiSettingsScreen(),
            ),
            // => '/devices/:name/settings', 상세 화면 우측 상단 설정 톱니바퀴.
            GoRoute(
              path: 'settings',
              builder: (context, state) => DeviceSettingsScreen(
                deviceOwnerName: state.pathParameters['name']!,
              ),
            ),
            // => '/devices/:name/stats', 상세 화면의 "루틴 통계 보기" 카드.
            GoRoute(
              path: 'stats',
              builder: (context, state) => DeviceStatsScreen(
                deviceOwnerName: state.pathParameters['name']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/profile', // 내 정보 탭
      builder: (context, state) => const ProfileScreen(),
      routes: [
        // => '/profile/edit', 프로필(아바타/닉네임) 관리.
        GoRoute(path: 'edit', builder: (context, state) => const ProfileEditScreen()),
        // => '/profile/language', 언어 선택.
        GoRoute(path: 'language', builder: (context, state) => const LanguageScreen()),
        // => '/profile/user-settings', 보호자 정보 + 로그아웃/탈퇴.
        GoRoute(
          path: 'user-settings',
          builder: (context, state) => const UserSettingsScreen(),
        ),
        // => '/profile/login-history', 로그인 기록.
        GoRoute(
          path: 'login-history',
          builder: (context, state) => const LoginHistoryScreen(),
        ),
      ],
    ),

    // 5) 하단 탭바에는 없지만 다른 화면에서 진입할 수 있는 화면들
    GoRoute(
      path: '/watch-connection', // 워치(손목 기기) BLE 페어링 화면
      builder: (context, state) => const WatchConnectionScreen(),
    ),
    // 홈/기기 상세 화면의 "연결된 기기" 카드를 누르면 도착하는 화면.
    // 두 탭(홈/기기)에서 공통으로 들어오는 화면이라 어느 한쪽 하위
    // 라우트로 넣지 않고 최상위에 뒀다.
    GoRoute(
      path: '/connected-devices',
      builder: (context, state) => const ConnectedDevicesScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddConnectedDeviceScreen(),
        ),
      ],
    ),
  ],
);
