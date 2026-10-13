import 'package:flutter/material.dart';

/// Figma(앱 최종) 브랜드 색. 로고·주요 버튼이 이 색이다.
const kBrandColor = Color(0xFF99B6FF);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: kBrandColor),
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
