import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding_providers.dart';
import 'widgets/step_dots.dart';

/// Figma: 예소 / 앱 초안 / Group 454 (node-id 279:1910) — 초기 설정 2단계.
///
/// 보호자 정보 다음 단계로, 자녀 이름과 생년월일을 입력받는다. 이후 단계
/// 화면은 아직 없어서 "다음으로"는 입력값을 저장한 뒤 임시로 홈으로 이동한다.
class ChildInfoScreen extends ConsumerStatefulWidget {
  const ChildInfoScreen({super.key});

  @override
  ConsumerState<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends ConsumerState<ChildInfoScreen> {
  static const _labelColor = Color(0xFF505050);
  static const _hintColor = Color(0xFFA3A3A3);
  static const _borderColor = Color(0xFFD9D9D9);
  static const _brandBlue = Color(0xFF4ABEFF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _year;
  int? _month;
  int? _day;

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
    await ref.read(onboardingRepositoryProvider).saveChildInfo(
          name: _nameController.text,
          birthDate: DateTime(_year!, _month!, _day!),
        );
    if (!mounted) return;
    context.push('/onboarding/device-connection');
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(20, (i) => currentYear - i);

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
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/onboarding/guardian-info'),
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
                const Center(child: StepDots(activeIndex: 1)),
                const Spacer(flex: 2),
                const Text(
                  '자녀 성명',
                  style: TextStyle(color: _labelColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration('ex. 홍길동'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '자녀 성명을 입력해주세요' : null,
                ),
                const SizedBox(height: 32),
                const Text(
                  '자녀 생년월일',
                  style: TextStyle(color: _labelColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 116,
                      child: DropdownButtonFormField<int>(
                        initialValue: _year,
                        decoration: _fieldDecoration('2026년'),
                        icon: const Icon(Icons.keyboard_arrow_down, color: _hintColor),
                        isExpanded: true,
                        items: years
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                            .toList(),
                        onChanged: (value) => setState(() => _year = value),
                        validator: (value) => value == null ? '' : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 86,
                      child: DropdownButtonFormField<int>(
                        initialValue: _month,
                        decoration: _fieldDecoration('6월'),
                        icon: const Icon(Icons.keyboard_arrow_down, color: _hintColor),
                        isExpanded: true,
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(value: m, child: Text('$m월')))
                            .toList(),
                        onChanged: (value) => setState(() => _month = value),
                        validator: (value) => value == null ? '' : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 104,
                      child: DropdownButtonFormField<int>(
                        initialValue: _day,
                        decoration: _fieldDecoration('25일'),
                        icon: const Icon(Icons.keyboard_arrow_down, color: _hintColor),
                        isExpanded: true,
                        items: List.generate(31, (i) => i + 1)
                            .map((d) => DropdownMenuItem(value: d, child: Text('$d일')))
                            .toList(),
                        onChanged: (value) => setState(() => _day = value),
                        validator: (value) => value == null ? '' : null,
                      ),
                    ),
                  ],
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
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      '두명 이상의 자녀와 사용할래요',
                      style: TextStyle(
                        color: Color(0xFFA5A5A5),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
