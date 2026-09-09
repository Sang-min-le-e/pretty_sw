import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Figma: 예소 / 소셜 로그인 화면 (node-id 392:5746, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 88" 프레임으로 저장돼 있었다). 카카오/네이버/
/// Apple/Google 버튼으로 로그인하는 원래 목업 디자인이다.
///
/// `login_screen.dart`의 문서 주석에 적혀 있듯, 이 앱은 "실제로는 이메일
/// 로그인만 사용하기로" 이미 정해서 그 화면을 기본 로그인 화면으로 쓰고
/// 있다. 이 화면은 그 결정을 뒤집는 게 아니라, 원래 디자인을 그대로 볼 수
/// 있게 이메일 로그인 화면 아래 "다른 방법으로 로그인" 링크로만 들어올 수
/// 있는 보조 화면으로 만들어뒀다 — 실제 카카오/네이버/Apple/Google SDK
/// 연동이 없어서 버튼을 눌러도 다음 화면(기본 정보 입력) 디자인만 보여줄
/// 뿐, 실제 로그인은 되지 않는다.
class LoginSocialScreen extends StatelessWidget {
  const LoginSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            SizedBox(width: 140, height: 155, child: SvgPicture.asset('assets/images/splash_logo.svg')),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _SocialButton(
                    label: '카카오로 시작하기',
                    background: const Color(0xFFFEE500),
                    foreground: Colors.black,
                    icon: Icons.chat_bubble,
                    onTap: () => context.push('/login/social/basic-info'),
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    label: '네이버로 시작하기',
                    background: const Color(0xFF03C75A),
                    foreground: Colors.white,
                    icon: Icons.abc,
                    onTap: () => context.push('/login/social/basic-info'),
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    label: 'Apple로 시작하기',
                    background: Colors.black,
                    foreground: Colors.white,
                    icon: Icons.apple,
                    onTap: () => context.push('/login/social/basic-info'),
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    label: 'Google로 시작하기',
                    background: Colors.white,
                    foreground: Colors.black,
                    border: true,
                    icon: Icons.g_mobiledata,
                    onTap: () => context.push('/login/social/basic-info'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                '이메일로 로그인',
                style: TextStyle(color: Color(0xFFA5A5A5), decoration: TextDecoration.underline),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
    this.border = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final bool border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: foreground),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          side: border ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
