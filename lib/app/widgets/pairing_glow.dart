import 'package:flutter/material.dart';

/// 기기를 찾는 동안(BLE 페어링 대기 등) 보여주는 은은한 확산광 효과.
/// 온보딩의 "기기 연결하기" 화면과 기기 탭의 "기기 추가하기" 화면이
/// 똑같은 연출을 쓰기 때문에 공용 위젯으로 뺐다.
class PairingGlow extends StatelessWidget {
  const PairingGlow({super.key, required this.child});

  final Widget child;
  static const _brandBlue = Color(0xFF4ABEFF);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 252,
          height: 252,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.transparent, _brandBlue.withValues(alpha: 0.15)],
              stops: const [0.8, 1.0],
            ),
          ),
        ),
        Container(
          width: 195,
          height: 195,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.transparent, _brandBlue.withValues(alpha: 0.25)],
              stops: const [0.68, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
