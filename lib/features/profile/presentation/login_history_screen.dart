import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';

/// Figma: 예소 / "로그인 기록" (node-id 392:5457, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 78" 프레임으로 저장돼 있었다). "내 정보" 화면의
/// "로그인 기록" 줄을 누르면 도착한다.
///
/// 실제 로그인 이력을 남기는 서버가 없어서, Figma 목업에 있던 예시 값을
/// 그대로 정적으로 보여준다.
class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  static const _entries = [
    ('iPhone 17 pro', '1분 전 접속'),
    ('iPhone 13', '2일 전 접속'),
    ('iPhone 11', '1년 7개월 전 접속'),
  ];

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
              BackHeader(title: '로그인 기록', onBack: () => context.pop()),
              const SizedBox(height: 24),
              for (final entry in _entries) ...[
                Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
                  ),
                  child: Row(
                    children: [
                      Text(
                        entry.$1,
                        style: const TextStyle(
                          color: Color(0xFF505050),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '・${entry.$2}',
                        style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFFA3A3A3)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
