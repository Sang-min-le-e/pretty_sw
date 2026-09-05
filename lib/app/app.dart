import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '루틴 앱',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
