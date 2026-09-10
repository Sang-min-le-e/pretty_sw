import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_providers.dart';

/// Figma: 예소 / 앱 초안 / Group 451 (node-id 279:1832) 의 로그아웃 화면.
///
/// 원본 디자인은 카카오/네이버/애플/구글 소셜 로그인 버튼이지만, 실제로는
/// 이메일 로그인만 사용하기로 해서 버튼 영역을 이메일/비밀번호 입력 폼으로
/// 바꿨다. 로고, 하단 회원가입/아이디·비밀번호 찾기 링크는 디자인 그대로 유지.
///
/// 로그인(`POST /auth/login`)에 성공하면 `GET /users/me`로 이 계정의
/// 보호자 성명이 저장돼 있는지를 확인해서, 아직 없는(최초 로그인) 계정이면
/// 초기 설정(보호자 정보) 화면으로, 이미 있으면 바로 홈으로 보낸다
/// (`docs/API.md` 5장 — `name`이 `null`이면 온보딩 1차 미완료).
///
/// 회원가입(`POST /auth/signup`) 화면은 아직 없어서, 이 폼은 이미 가입된
/// 계정으로 로그인하는 것만 가능하다 — "회원가입" 링크는 그래서 지금도
/// 반응하지 않는다.
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
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // 로그인 응답에는 온보딩 완료 여부를 알려주는 name이 없다(4장) —
      // 로그인 직후 한 번 더 불러야 한다(5장).
      final me = await ref.read(userRepositoryProvider).getMe();
      if (!mounted) return;
      context.go(me.name == null ? '/onboarding/guardian-info' : '/');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('로그인'),
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
              // 원래 Figma 목업이던 소셜 로그인 화면은 지워지지 않았다 —
              // 이 링크로 그 디자인을 그대로 볼 수 있게 남겨뒀다(자세한
              // 이유는 이 파일 위쪽 문서 주석 참고). 실제 로그인 수단은
              // 여전히 이메일뿐이다.
              TextButton(
                onPressed: () => context.push('/login/social'),
                child: const Text(
                  '다른 방법으로 로그인',
                  style: TextStyle(
                    color: Color(0xFFA5A5A5),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
