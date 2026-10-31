import 'package:flutter/material.dart';

import '../../domain/app_notification.dart';

/// Figma: 예소 / 홈 알림 팝업(node-id 147:2200 안의 147:2267·2270). 알림 한 건을
/// 보여주는 367×59 알약 모양 카드. [pointer]가 true면 오른쪽 위에 벨을 가리키는
/// 작은 꼬리가 붙는다(벨을 눌러 연 팝업의 맨 윗 카드).
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification, this.pointer = false});

  final AppNotification notification;
  final bool pointer;

  static const color = Color(0xFFF2F2F2);
  static const _titleColor = Color(0xFF505050);
  static const _bodyColor = Color(0xFF898989);
  static const _timeColor = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 59,
      padding: const EdgeInsets.only(left: 24, right: 29),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: _titleColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title.isEmpty ? '알림' : notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  notification.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _bodyColor, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            relativeTimeLabel(notification.createdAt),
            style: const TextStyle(
              color: _timeColor,
              fontSize: 10,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );

    if (!pointer) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        const Positioned(top: -9, right: 38, child: _Pointer()),
      ],
    );
  }
}

/// "방금 전 / N분 전 / N시간 전 / M월 D일".
String relativeTimeLabel(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${t.month}월 ${t.day}일';
}

class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(14, 10), painter: _PointerPainter());
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height + 1)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height + 1)
      ..close();
    canvas.drawPath(path, Paint()..color = NotificationCard.color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
