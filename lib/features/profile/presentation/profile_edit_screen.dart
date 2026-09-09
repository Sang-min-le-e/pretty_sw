import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';

/// Figma: 예소 / "프로필 관리" (node-id 392:5446, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 77" 프레임으로 저장돼 있었다). "내 정보" 화면의
/// 프로필 줄을 누르면 도착한다.
///
/// 아바타 사진 업로드는 실제 파일 저장소가 없어서(다른 온보딩/기기 화면과
/// 같은 이유) 눌러도 반응하지 않고, 닉네임만 로컬에서 수정할 수 있다.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nicknameController = TextEditingController(text: '백지예');

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFFCACACA),
                      child: Icon(Icons.person, color: Colors.white, size: 52),
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
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ABEFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('완료', style: TextStyle(fontSize: 22)),
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
