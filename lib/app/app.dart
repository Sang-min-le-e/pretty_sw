import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/notifications/presentation/widgets/notification_toast_host.dart';
import 'router.dart';
import 'theme.dart';

class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TOMO',
      theme: appTheme,
      // 시간·날짜 선택창의 "오전/오후"와 버튼 글자가 한국어로 나오게 한다.
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      // 새 알림이 오면 어느 화면에서든 위에 토스트가 뜬다.
      builder: (context, child) => NotificationToastHost(child: child),
    );
  }
}
