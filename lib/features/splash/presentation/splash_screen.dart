import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Figma: 예소 / 앱 최종 / iPhone 17 - 103 (node-id 508:6190)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo_tomo.png',
          width: 200,
          height: 73,
        ),
      ),
    );
  }
}
