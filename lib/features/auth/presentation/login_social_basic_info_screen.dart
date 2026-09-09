import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';

/// Figma: 예소 / "기본 정보 입력" (node-id 400:6233, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 89" 프레임으로 저장돼 있었다). 소셜 로그인
/// 버튼([LoginSocialScreen]) 중 하나를 누르면 도착하는 다음 단계 디자인.
///
/// 실제 소셜 로그인 SDK가 붙어있지 않아 여기까지는 그냥 화면 구경용이다
/// — "시작하기"를 눌러도 실제로 로그인/가입이 되지는 않는다.
class LoginSocialBasicInfoScreen extends StatefulWidget {
  const LoginSocialBasicInfoScreen({super.key});

  @override
  State<LoginSocialBasicInfoScreen> createState() => _LoginSocialBasicInfoScreenState();
}

class _LoginSocialBasicInfoScreenState extends State<LoginSocialBasicInfoScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
              BackHeader(title: '기본 정보 입력', onBack: () => context.pop()),
              const SizedBox(height: 24),
              const Text('보호자 성명', style: TextStyle(color: Color(0xFF505050), fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF505050), fontSize: 16),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'ex. 홍길동',
                    hintStyle: TextStyle(color: Color(0xFFA3A3A3)),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 실제 소셜 로그인 연동이 없어서 가입을 완료할 수
                    // 없다 — 준비 중이라는 안내만 보여준다.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('소셜 로그인 연동은 아직 준비 중이에요')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ABEFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('시작하기', style: TextStyle(fontSize: 22)),
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
