import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import 'widgets/settings_card.dart';

/// Figma: 예소 / "사용자 설정" (node-id 392:5512, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 80" 프레임으로 저장돼 있었다. 로그아웃/탈퇴
/// 확인 다이얼로그가 열린 상태의 변형인 415:2152/415:2166은 별도 화면이
/// 아니라 이 화면 위에 [showDialog]로 띄운다). "내 정보" 화면의 "사용자
/// 설정" 줄을 누르면 도착한다.
class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              BackHeader(title: '사용자 설정', onBack: () => context.pop()),
              const SizedBox(height: 24),
              const SettingsCard(
                children: [
                  SettingsChevronRow(label: '보호자 설정'),
                  SettingsValueRow(label: '보호자 성명', value: '백지예'),
                  SettingsValueRow(label: '전화번호', value: '010-1234-5678'),
                ],
              ),
              const Spacer(),
              _DangerButton(
                label: '로그아웃',
                filled: false,
                onTap: () => _confirm(
                  context,
                  title: '로그아웃 하시겠습니까?',
                  content: '다시 로그인해야 정보를 가져올 수 있습니다.',
                  confirmLabel: '로그아웃하기',
                ),
              ),
              const SizedBox(height: 10),
              _DangerButton(
                label: '탈퇴하기',
                filled: true,
                onTap: () => _confirm(
                  context,
                  title: '탈퇴 하시겠습니까?',
                  content: '기기 연결이 끊어지며, 앱에 저장된 정보가 모두 삭제됩니다.',
                  confirmLabel: '탈퇴하기',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel, style: const TextStyle(color: Color(0xFFE71A1A))),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go('/login');
    }
  }
}

/// "로그아웃"(흰 배경) / "탈퇴하기"(연빨강 배경) 알약 버튼.
class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFFE6E6) : Colors.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: filled
              ? null
              : const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4)],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFE71A1A), fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
