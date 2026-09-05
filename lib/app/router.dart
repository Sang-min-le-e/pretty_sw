import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/onboarding/presentation/child_info_screen.dart';
import '../features/onboarding/presentation/device_connection_screen.dart';
import '../features/onboarding/presentation/guardian_info_screen.dart';
import '../features/routine/presentation/routine_list_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/watch_connection/presentation/watch_connection_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
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
      path: '/onboarding/device-connection',
      builder: (context, state) => const DeviceConnectionScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const RoutineListScreen(),
    ),
    GoRoute(
      path: '/watch-connection',
      builder: (context, state) => const WatchConnectionScreen(),
    ),
  ],
);
