import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../children/data/child_providers.dart';
import '../data/auth_providers.dart';

/// Figma: 예소 / 앱 초안 / Group 451 (node-id 279:1832) 의 로그아웃 화면.
///
/// 로그인(`POST /auth/login`)에 성공하면 응답에 든 `user.name`으로 이 계정의
/// 보호자 성명이 저장돼 있는지를 확인해서, 아직 없는(최초 로그인) 계정이면
/// 초기 설정(보호자 정보) 화면으로, 이미 있으면 바로 홈으로 보낸다
/// (`docs/API.md` 5장 — `name`이 `null`이면 온보딩 1차 미완료).
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
      // login()은 서버가 로그인 응답에 담아 준 user(`docs/API.md` 4장)를
      // AuthUser로 바꿔 돌려준다. name이 null이면 온보딩 1차를 아직 안 마친
      // 계정이므로, GET /users/me를 한 번 더 부를 필요 없이 이 값으로 바로
      // 분기한다.
      final user = await ref.read(authRepositoryProvider).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // 이전에 다른 계정으로 로그인했다면 그 계정의 자녀 목록·선택이 캐시에 남아
      // 있으니 버린다(다음에 읽을 때 이 계정 것을 새로 받아온다).
      ref.invalidate(childListProvider);
      ref.invalidate(selectedChildIdProvider);
      if (!mounted) return;
      context.go(user.name == null ? '/onboarding/guardian-info' : '/');
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
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
