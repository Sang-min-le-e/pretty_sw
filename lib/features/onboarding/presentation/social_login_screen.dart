import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 초기 설정의 첫 화면 — "소셜 로그인 (구글, 카카오 등)".
///
/// 실제 OAuth 연동(구글/카카오 SDK)은 백엔드 파트와 클라이언트 ID, 리다이렉트
/// 방식을 먼저 맞춰야 붙일 수 있는 부분이라, 지금은 버튼만 만들어두고 눌렀을 때
/// 바로 다음 단계(보호자 정보 입력)로 넘어가게만 해뒀다. 나중에 실제 로그인
/// SDK를 붙일 때는 이 onPressed 안의 `context.push(...)` 호출 자리에
/// "로그인 성공 콜백"을 연결하면 된다.
class SocialLoginScreen extends StatelessWidget {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.watch, size: 64),
              const SizedBox(height: 16),
              Text('루틴 앱에 오신 걸 환영해요', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('보호자 계정으로 로그인해주세요', textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => context.push('/onboarding/guardian-info'),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('구글로 계속하기'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/onboarding/guardian-info'),
                icon: const Icon(Icons.chat_bubble),
                label: const Text('카카오로 계속하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
