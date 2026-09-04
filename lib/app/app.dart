import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

class RoutineApp extends StatelessWidget {
  const RoutineApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '루틴 앱',
      theme: appTheme,
      routerConfig: router,
      // 자녀 생년월일 선택(showDatePicker)이나 달력(table_calendar)이 한국어로
      // 나오려면 Flutter의 기본 위젯 문자열(요일, "취소/확인" 버튼 등)도 한국어
      // 번역 데이터가 필요하다. 이 delegate들이 그 번역 데이터를 제공한다.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
    );
  }
}
