import 'package:flutter/material.dart';

/// 지적장애인 대상 UI: 큰 터치 타겟, 높은 대비, 큰 텍스트를 기본값으로 삼는다.
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  visualDensity: VisualDensity.comfortable,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 20),
    bodyMedium: TextStyle(fontSize: 18),
    titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(88, 56),
      textStyle: const TextStyle(fontSize: 20),
    ),
  ),
);
