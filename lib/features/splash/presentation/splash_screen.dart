import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_providers.dart';

/// Figma: 예소 / 앱 최종 / iPhone 17 - 103 (node-id 508:6190)
///
/// 로고를 잠깐 보여주는 동안 저장된 로그인 세션을 확인한다. 세션이 서버에서도
/// 유효하면(`GET /users/me` 성공) 로그인 화면을 건너뛰고 바로 홈(또는 온보딩)으로
/// 가고, 세션이 없거나 만료됐거나 서버에 닿지 못하면 로그인 화면으로 간다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minShown = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final minShown = Future<void>.delayed(_minShown);
    final destination = await _destination();
    await minShown;
    if (mounted) context.go(destination);
  }

  Future<String> _destination() async {
    try {
      final session = ref.read(authSessionRepositoryProvider);
      if (await session.getAccessUuid() == null) return '/login';
      final user = await ref.read(userRepositoryProvider).getMe();
      return user.name == null ? '/onboarding/guardian-info' : '/';
    } on ApiException catch (e) {
      // 세션이 서버에서 무효(401)면 저장된 값을 지우고 로그인으로. 그 외(서버에 못 닿음
      // 등)는 지우지 않는다 — 네트워크가 돌아오면 다음 실행에서 자동 로그인이 된다.
      if (e.statusCode == 401) {
        await ref.read(authSessionRepositoryProvider).clearAccessUuid();
      }
      return '/login';
    } catch (_) {
      return '/login';
    }
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
