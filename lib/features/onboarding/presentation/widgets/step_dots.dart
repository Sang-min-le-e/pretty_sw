import 'package:flutter/material.dart';

/// 초기 설정 흐름 상단의 3단계 진행 표시 점.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.activeIndex});

  final int activeIndex;
  static const _count = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_count, (index) {
        final active = index == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF4ABEFF) : const Color(0xFFD9D9D9),
            ),
          ),
        );
      }),
    );
  }
}
