import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/data/onboarding_providers.dart';

/// Figma: 예소 / 앱 초안 / Group 451 (node-id 279:1832) 의 로그아웃 화면.
///
/// 원본 디자인은 카카오/네이버/애플/구글 소셜 로그인 버튼이지만, 실제로는
/// 이메일 로그인만 사용하기로 해서 버튼 영역을 이메일/비밀번호 입력 폼으로
/// 바꿨다. 로고, 하단 회원가입/아이디·비밀번호 찾기 링크는 디자인 그대로 유지.
///
/// 로그인에 성공하면 이 계정에 보호자 정보가 저장돼 있는지를 확인해서,
/// 로그인 내역이 없는 최초 로그인이면 초기 설정(보호자 정보) 화면으로,
/// 이미 설정을 마친 계정이면 바로 홈으로 보낸다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _brandBlue = Color(0xFF4ABEFF);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final hasGuardianInfo = await ref.read(onboardingRepositoryProvider).hasGuardianInfo();
    if (!mounted) return;
    context.go(hasGuardianInfo ? '/' : '/onboarding/guardian-info');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Spacer(flex: 3),
              SizedBox(
                width: 140,
                height: 155,
                child: SvgPicture.asset('assets/images/splash_logo.svg'),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        labelStyle: TextStyle(color: Color(0xFFBDBDBD)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(19)),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? '이메일을 입력해주세요' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        labelStyle: TextStyle(color: Color(0xFFBDBDBD)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(19)),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? '비밀번호를 입력해주세요' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
                          ),
                        ),
                        child: const Text('로그인'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Color(0xFFA5A5A5),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '아이디/비밀번호 찾기',
                      style: TextStyle(
                        color: Color(0xFFA5A5A5),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
