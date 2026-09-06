import 'package:flutter/material.dart';

import '../../../app/widgets/bottom_nav_bar.dart';

/// 하단 탭바의 "내 정보" 탭. 실제 프로필 화면은 아직 디자인이 없어서 자리만
/// 잡아둔 화면이고, 탭 이동이 되는지 확인하는 용도다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: const SafeArea(
        child: Center(
          child: Text(
            '내 정보 화면\n준비 중이에요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF505050),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
