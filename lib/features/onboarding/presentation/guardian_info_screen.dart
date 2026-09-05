import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding_providers.dart';
import 'widgets/step_dots.dart';

/// Figma: 예소 / 앱 초안 / Group 453 (node-id 279:1891) — 초기 설정 1단계.
///
/// 로그인 내역이 없는 계정이 처음 로그인했을 때 보여주는 초기 설정 흐름의
/// 첫 화면으로, 보호자 이름과 자녀와의 관계를 입력받는다.
class GuardianInfoScreen extends ConsumerStatefulWidget {
  const GuardianInfoScreen({super.key});

  @override
  ConsumerState<GuardianInfoScreen> createState() => _GuardianInfoScreenState();
}

class _GuardianInfoScreenState extends ConsumerState<GuardianInfoScreen> {
  static const _labelColor = Color(0xFF505050);
  static const _hintColor = Color(0xFFA3A3A3);
  static const _borderColor = Color(0xFFD9D9D9);
  static const _brandBlue = Color(0xFF4ABEFF);

  static const _relationships = ['부', '모', '조부모', '기타'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _relationship;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontWeight: FontWeight.w300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    await ref.read(onboardingRepositoryProvider).saveGuardianInfo(
          name: _nameController.text,
          relationship: _relationship!,
        );
    if (!mounted) return;
    context.push('/onboarding/child-info');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.chevron_left, size: 32, color: _labelColor),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/login'),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    '시작하기 전,\n몇가지 확인이 필요해요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _labelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: StepDots(activeIndex: 0)),
                const Spacer(flex: 2),
                const Text(
                  '보호자 성명',
                  style: TextStyle(color: _labelColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration('ex. 홍길동'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '보호자 성명을 입력해주세요' : null,
                ),
                const SizedBox(height: 32),
                const Text(
                  '자녀와의 관계',
                  style: TextStyle(color: _labelColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _relationship,
                  decoration: _fieldDecoration('선택하세요'),
                  icon: const Icon(Icons.keyboard_arrow_down, color: _hintColor),
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) => setState(() => _relationship = value),
                  validator: (value) => value == null ? '자녀와의 관계를 선택해주세요' : null,
                ),
                const Spacer(flex: 5),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('다음으로', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
