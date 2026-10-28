import 'package:flutter/material.dart';

/// Figma "로그아웃/탈퇴 확인 창"(iPhone 17 - 101, 102). 제목(굵게 13) + 설명(11) 아래에
/// 분홍 "확인" 버튼과 회색 "취소" 버튼이 세로로 쌓인 알림 창.
///
/// 확인을 누르면 `true`, 취소하거나 바깥을 누르면 `false`를 돌려준다.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = '취소',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 13,
                  height: 16 / 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6E6E73),
                  fontSize: 11,
                  height: 14 / 11,
                ),
              ),
              const SizedBox(height: 16),
              _DialogButton(
                label: confirmLabel,
                background: const Color(0xFFFFCDCD),
                foreground: const Color(0xFFFF0000),
                onTap: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: 6),
              _DialogButton(
                label: cancelLabel,
                background: const Color(0xFFE9E9EB),
                foreground: const Color(0xFF505050),
                onTap: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 34,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100)),
        child: Text(
          label,
          style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
