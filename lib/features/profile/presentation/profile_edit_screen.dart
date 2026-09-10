import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../data/avatar_providers.dart';

/// Figma: 예소 / "프로필 관리" (node-id 392:5446, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 77" 프레임으로 저장돼 있었다). "내 정보" 화면의
/// 프로필 줄을 누르면 도착한다.
///
/// 아바타 사진은 백엔드에 업로드 API가 없어서(`docs/API.md`에 프로필
/// 이미지 필드가 없다) 서버로 올리지는 않고, 기기 로컬에만 저장한다
/// (`avatar_providers.dart`). 닉네임은 `PATCH /users/me`(백엔드 필드명은
/// `name`)로 저장한다 — 별도의 "닉네임" 컬럼은 없고, 온보딩 1차에서 쓰는
/// "보호자 성명"과 같은 값이다.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateMe(name: _nicknameController.text);
      // 캐시해둔 계정 정보를 무효화해서, 이 화면을 나갔을 때 "내 정보"
      // 헤더·사용자 설정 화면이 새 이름을 다시 받아오게 한다.
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 서버에서 받아온 이름이 도착하면 한 번만 입력창을 채운다 — 매
    // build마다 덮어쓰면 사용자가 입력 중인 값이 지워지기 때문에
    // [_prefilled] 플래그로 최초 1회만 반영한다.
    final userAsync = ref.watch(currentUserProvider);
    final name = userAsync.value?.name;
    if (!_prefilled && name != null) {
      _prefilled = true;
      _nicknameController.text = name;
    }
    final avatarPath = ref.watch(avatarPathProvider).value;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              BackHeader(title: '프로필 관리', onBack: () => context.pop()),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () => ref.read(avatarActionsProvider).pickAndSaveAvatar(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFFCACACA),
                        backgroundImage: avatarPath == null ? null : FileImage(File(avatarPath)),
                        child: avatarPath == null
                            ? const Icon(Icons.person, color: Colors.white, size: 52)
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ABEFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('닉네임', style: TextStyle(color: Color(0xFF505050), fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Color(0xFF505050), fontSize: 14),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ABEFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('완료', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
