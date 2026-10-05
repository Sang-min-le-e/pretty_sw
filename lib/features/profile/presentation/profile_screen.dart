import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/account_actions.dart';
import '../../auth/data/auth_providers.dart';
import '../data/avatar_providers.dart';
import 'widgets/settings_card.dart';

/// Figma: 예소 / "내 정보" (node-id 392:5396, "앱 초안 3" 프레임 안, 이름
/// 없는 "iPhone 17 - 76" 프레임으로 저장돼 있었다). 하단 탭바의 "내 정보" 탭.
///
/// 프로필 카드(아바타+이름, 눌러서 "프로필 관리"로 이동) 아래 2개 설정
/// 카드(앱 설정 / 계정)와 로그아웃·탈퇴·앱 버전 카드로 이뤄진다. Figma
/// 목업에 있던 "이용 안내"(고객센터/약관 및 정책) 카드는 보여줄 실제
/// 문서·채널이 없어서 뺐다.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _labelColor = Color(0xFF505050);

  // 알림/다크모드는 아직 실제로 알림을 끄거나 앱 전체 테마를 바꾸는
  // 기능과 연결돼 있지 않다(테마는 lib/app/theme.dart에 고정) — 이
  // 화면 안에서만 켜고 끌 수 있는 상태로 우선 자리를 잡아뒀다.
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    // 로딩/에러 중엔 빈 문자열로 둔다 — 이 탭에 왔다는 건 이미 로그인이
    // 끝난 상태라 보통 순간적으로만 비어 보인다.
    final userName = userAsync.value?.name ?? '';
    final avatarPath = ref.watch(avatarPathProvider).value;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 정보',
                style: TextStyle(color: _labelColor, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.push('/profile/edit'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFCACACA),
                      backgroundImage: avatarPath == null ? null : FileImage(File(avatarPath)),
                      child: avatarPath == null
                          ? const Icon(Icons.person, color: Colors.white, size: 26)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(color: _labelColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: const [
                            Text('프로필 관리', style: TextStyle(color: Color(0xFF7F7F7F), fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 14, color: Color(0xFF7F7F7F)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SettingsCard(
                title: '앱 설정',
                children: [
                  SettingsChevronRow(
                    label: '언어',
                    value: '한국어',
                    valueColor: const Color(0xFF4ABEFF),
                    onTap: () => context.push('/profile/language'),
                  ),
                  SettingsSwitchRow(
                    label: '알림',
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  SettingsSwitchRow(
                    label: '다크모드',
                    value: _darkModeEnabled,
                    onChanged: (v) => setState(() => _darkModeEnabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SettingsCard(
                title: '계정',
                children: [
                  SettingsChevronRow(
                    label: '사용자 설정',
                    onTap: () => context.push('/profile/user-settings'),
                  ),
                  SettingsChevronRow(
                    label: '로그인 기록',
                    onTap: () => context.push('/profile/login-history'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SettingsCard(
                children: [
                  const SettingsValueRow(label: '앱 버전', value: '0.1.0'),
                  SettingsChevronRow(label: '로그아웃', onTap: () => _confirmLogout(context)),
                  SettingsChevronRow(
                    label: '탈퇴하기',
                    danger: true,
                    onTap: () => _confirmWithdraw(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 하시겠습니까?'),
        content: const Text('다시 로그인해야 정보를 가져올 수 있습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃하기', style: TextStyle(color: Color(0xFFE71A1A))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // 서버 `access_uuid` 무효화까지 기다린 다음 이동한다 — 로그아웃
      // API가 실패해도 로컬 세션은 지워지므로(auth_repository.dart의
      // finally) 화면 전환 자체는 항상 일어난다.
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) context.go('/login');
    }
  }

  // 탈퇴하기: 서버에 `DELETE /users/me`를 보내 계정과 딸린 데이터를 지우고,
  // 성공하면 이 기기에 남은 데이터(Hive, 프로필 사진, 캐시)도 지운 뒤
  // 로그인 화면으로 보낸다(`AccountActions.withdraw`). 서버 호출이 실패하면
  // 아무것도 지우지 않고 오류 문구만 보여준다.
  Future<void> _confirmWithdraw(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('탈퇴 하시겠습니까?'),
        content: const Text('기기 연결이 끊어지며, 앱에 저장된 정보가 모두 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('탈퇴하기', style: TextStyle(color: Color(0xFFE71A1A))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(accountActionsProvider).withdraw();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (context.mounted) context.go('/login');
  }
}
