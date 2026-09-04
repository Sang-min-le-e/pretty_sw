import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/onboarding_providers.dart';
import '../domain/child_profile.dart';

/// 초기 설정 2차: 자녀 성명 / 생년월일 입력.
class ChildInfoScreen extends ConsumerStatefulWidget {
  const ChildInfoScreen({super.key});

  @override
  ConsumerState<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends ConsumerState<ChildInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid || _birthDate == null) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('생년월일을 선택해주세요')));
      }
      return;
    }

    final child = ChildProfile(name: _nameController.text.trim(), birthDate: _birthDate!);
    await ref.read(onboardingActionsProvider).saveChild(child);

    if (!mounted) return;
    context.push('/onboarding/device-pairing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자녀 정보')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '자녀 성명'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '이름을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _pickBirthDate,
                  child: Text(
                    _birthDate == null
                        ? '생년월일 선택'
                        : DateFormat('yyyy.MM.dd').format(_birthDate!),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(onPressed: _submit, child: const Text('다음')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
