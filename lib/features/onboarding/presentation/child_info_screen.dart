import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../children/data/child_providers.dart';

/// Figma: 예소 / 앱 초안 / Group 454 (node-id 279:1910).
///
/// 관리자(선생님)가 학생을 등록하는 화면. 학생 이름·생년월일을 입력받아
/// `POST /children`으로 등록한다(`docs/API.md` 6장). 서버에서는 학생이
/// "자녀(child)"로 불리며, 관리자 계정이라 `relationship`은 항상 `ADMIN`이다.
/// 초기 설정 흐름에서는 빠졌고, 루틴 탭의 학생 선택 줄에서 `/children/new`로
/// 들어온다.
class ChildInfoScreen extends ConsumerStatefulWidget {
  const ChildInfoScreen({super.key});

  @override
  ConsumerState<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends ConsumerState<ChildInfoScreen> {
  static const _labelColor = Color(0xFF505050);
  static const _hintColor = Color(0xFFA3A3A3);
  static const _borderColor = Color(0xFFD9D9D9);
  static const _brandBlue = Color(0xFF99B6FF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _year;
  int? _month;
  int? _day;
  bool _submitting = false;

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
    setState(() => _submitting = true);
    try {
      final child = await ref.read(childRepositoryProvider).createChild(
            name: _nameController.text,
            birthDate: DateTime(_year!, _month!, _day!),
            relationship: 'ADMIN',
          );
      // 루틴 탭의 자녀 선택에 방금 등록한 자녀가 바로 보이고 선택돼 있도록
      // 목록을 새로 받고 이 자녀를 고른 상태로 둔다.
      ref.invalidate(childListProvider);
      ref.read(selectedChildIdProvider.notifier).state = child.childId;
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go('/routine');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                  onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    '학생을 등록해주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _labelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const Text(
                  '학생 성명',
                  style: TextStyle(color: _labelColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration('ex. 홍길동'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '학생 성명을 입력해주세요' : null,
                ),
                const SizedBox(height: 32),
                const Text(
                  '학생 생년월일',
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
                        : const Text('등록하기', style: TextStyle(fontSize: 22)),
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
