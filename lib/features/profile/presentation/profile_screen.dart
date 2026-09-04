import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/data/onboarding_providers.dart';

/// 하단 탭바의 "프로필" 탭 = 목업의 "내 정보" 화면.
///
/// 목업에는 계정/앱 설정/기기 설정/도움말 섹션이 있었는데, 지금 실제로 값이
/// 있는 건 보호자 이름/관계(온보딩 때 입력받은 값)뿐이라 나머지 항목은
/// 눌러도 아무 일도 안 일어나는 정적인 목록으로만 넣어뒀다. "로그아웃"만
/// 실제로 동작한다 — 온보딩 데이터를 지우고 초기 설정 화면으로 돌려보낸다.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingActionsProvider).logout();
    if (!context.mounted) return;
    context.go('/onboarding/social-login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianAsync = ref.watch(guardianProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        children: [
          guardianAsync.when(
            data: (guardian) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(guardian?.name ?? '보호자'),
              subtitle: Text(guardian == null ? '' : '보호자 · ${guardian.relationship}'),
            ),
            loading: () => const ListTile(leading: CircularProgressIndicator()),
            error: (error, stack) => ListTile(title: Text('불러오기 실패: $error')),
          ),
          const _SectionLabel('계정'),
          const ListTile(leading: Icon(Icons.settings_outlined), title: Text('사용자 설정')),
          const ListTile(leading: Icon(Icons.watch_outlined), title: Text('페어링 관리')),
          const _SectionLabel('앱 설정'),
          const ListTile(leading: Icon(Icons.language), title: Text('언어'), trailing: Text('한국어')),
          const _SectionLabel('도움말'),
          const ListTile(leading: Icon(Icons.support_agent_outlined), title: Text('고객센터')),
          const ListTile(leading: Icon(Icons.description_outlined), title: Text('약관 및 정책')),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('앱 버전 0.1.0')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton(
              onPressed: () => _logout(context, ref),
              child: const Text('로그아웃'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
