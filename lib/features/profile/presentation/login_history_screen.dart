import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../auth/data/auth_providers.dart';

/// Figma: 예소 / "로그인 기록" (node-id 392:5457, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 78" 프레임으로 저장돼 있었다). "내 정보" 화면의
/// "로그인 기록" 줄을 누르면 도착한다.
///
/// 서버에 로그인 기록 API가 없어서, 이 기기에서 마지막으로 로그인한 시각
/// ([lastLoginAtProvider]) 한 줄만 진짜 값으로 보여준다. 다른 기기의 접속
/// 기록은 알 수 없다.
class LoginHistoryScreen extends ConsumerWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastLoginAt = ref.watch(lastLoginAtProvider).value;
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
              if (lastLoginAt != null)
                _EntryCard(name: '이 기기', detail: '${_elapsed(lastLoginAt)} 접속')
              else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '이 기기의 로그인 기록이 아직 없어요',
                    style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 14),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF99B6FF),
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

  /// "방금", "5분 전", "3시간 전", "2일 전", "1달 전", "1년 전".
  static String _elapsed(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 30) return '${diff.inDays}일 전';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}달 전';
    return '${diff.inDays ~/ 365}년 전';
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            name,
            style: const TextStyle(
              color: Color(0xFF505050),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '・$detail',
            style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
