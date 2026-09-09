import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 원형 진행률 게이지. Figma 원본은 66% 상태 하나만 정적 이미지로 내보내져
/// 있어서(비율이 바뀌는 다른 화면엔 쓸 수 없다), 루틴 완료율(상세 화면)과
/// 기기 통계(하루/일주일/한달 성취도)처럼 실제 비율이 화면마다 다른 곳에서
/// 공통으로 쓰려고 `CustomPainter`로 직접 그린다 — 회색 트랙 위에 파란
/// 호를 12시 방향부터 시계 방향으로 [ratio]만큼 그리고 가운데에 [center]
/// 위젯(보통 퍼센트 숫자)을 겹쳐 쓴다.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.ratio, required this.center, this.diameter = 200});

  final double ratio;
  final Widget center;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(diameter),
            painter: _ProgressRingPainter(ratio: ratio),
          ),
          center,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.ratio});

  final double ratio;

  static const _trackColor = Color(0xFFEAEAEA);
  static const _progressColor = Color(0xFF4ABEFF);
  static const _strokeWidth = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = _trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;
    final progressPaint = Paint()
      ..color = _progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    // -90도(12시 방향)에서 시작해서 시계 방향으로 ratio만큼(최대 360도) 그린다.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ratio.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}
