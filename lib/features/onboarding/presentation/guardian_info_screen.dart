import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_providers.dart';

/// Figma: 예소 / 앱 최종 / iPhone 17 - 105 (node-id 508:6226) — 초기 설정 1단계.
///
/// 로그인 내역이 없는 계정이 처음 로그인했을 때 보여주는 초기 설정의
/// 유일한 화면으로, 관리자(선생님) 이름을 입력받아 `PATCH /users/me`로
/// 저장하고 곧바로 홈으로 간다(`docs/API.md` 5장). 학생 등록과 기기 연결은
/// 초기 설정에서 빠졌다(학생은 루틴 탭에서, 기기는 기기 탭에서 추가).
class GuardianInfoScreen extends ConsumerStatefulWidget {
  const GuardianInfoScreen({super.key});

  @override
  ConsumerState<GuardianInfoScreen> createState() => _GuardianInfoScreenState();
}

class _GuardianInfoScreenState extends ConsumerState<GuardianInfoScreen> {
  static const _labelColor = Color(0xFF505050);
  static const _hintColor = Color(0xFFA3A3A3);
  static const _borderColor = Color(0xFFD9D9D9);
  static const _chevronColor = Color(0xFFA9A9A9);
  static const _brandBlue = Color(0xFF99B6FF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _hintColor,
        fontSize: 14,
        fontWeight: FontWeight.w300,
        height: 1.36,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(userRepositoryProvider).updateMe(name: _nameController.text);
      if (!mounted) return;
      context.go('/');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 글자 왼쪽 끝이 화면 왼쪽에서 59px(Figma)에 오도록 맞춘 여백.
              Padding(
                padding: const EdgeInsets.only(left: 31, top: 7),
                child: BackHeader(
                  title: '기본 정보 입력',
                  chevronColor: _chevronColor,
                  onBack: () => context.canPop() ? context.pop() : context.go('/login'),
                ),
              ),
              const SizedBox(height: 106),
              const Padding(
                padding: EdgeInsets.only(left: 55),
                child: Text(
                  '보호자 성명',
                  style: TextStyle(
                    color: _labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.36,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 42),
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14, height: 1.36),
                  decoration: _fieldDecoration('ex. 홍길동'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '보호자 성명을 입력해주세요' : null,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 49),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('시작하기', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              const SizedBox(height: 62),
            ],
          ),
        ),
      ),
    );
  }
}
