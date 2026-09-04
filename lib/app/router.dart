import 'package:go_router/go_router.dart';

import '../features/routine/presentation/routine_list_screen.dart';
import '../features/watch_connection/presentation/watch_connection_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
