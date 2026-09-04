import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding_providers.dart';
import '../domain/guardian_profile.dart';

/// 초기 설정 1차: 보호자 성명 / 관계 입력.
///
/// `ConsumerStatefulWidget`을 쓴 이유: 이 화면은 TextEditingController처럼
/// "위젯이 화면에서 사라질 때 반드시 정리(dispose)해야 하는" 상태를 갖고 있다.
/// `ConsumerWidget`(StatelessWidget + Riverpod)만으로는 이런 생명주기 관리가
/// 안 되기 때문에, State가 필요한 화면은 ConsumerStatefulWidget을 쓴다.
class GuardianInfoScreen extends ConsumerStatefulWidget {
  const GuardianInfoScreen({super.key});

  @override
  ConsumerState<GuardianInfoScreen> createState() => _GuardianInfoScreenState();
}

class _GuardianInfoScreenState extends ConsumerState<GuardianInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final guardian = GuardianProfile(
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
    );
    // ref.read를 쓰는 이유: 이건 "지금 이 순간 한 번 실행할 동작"이지 화면을
    // 다시 그리기 위해 값의 변화를 계속 지켜봐야(watch) 하는 게 아니기 때문이다.
    // Riverpod에서는 "값을 읽어서 화면을 그린다"는 watch, "이벤트에 반응해서
    // 한 번 실행한다"는 read를 구분해서 쓰는 게 관례다.
    await ref.read(onboardingActionsProvider).saveGuardian(guardian);

    if (!mounted) return;
    context.push('/onboarding/child-info');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보호자 정보')),
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
                  decoration: const InputDecoration(labelText: '보호자 성명'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '이름을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(
                    labelText: '자녀와의 관계',
                    hintText: '예: 부모, 조부모, 활동지원사',
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '관계를 입력해주세요' : null,
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
