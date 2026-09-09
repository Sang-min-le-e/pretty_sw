import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/device_overview.dart';

/// 흰 알약 모양 입력 줄: 왼쪽 굵은 라벨 + 오른쪽 입력값(또는 값 텍스트).
/// "WIFI 설정"(8-1-1)과 "기기 추가하기"(8-6) 2단계의 WIFI 정보 입력이
/// 똑같은 모양을 쓰기 때문에 공용 위젯으로 뺐다.
class LabeledFieldRow extends StatelessWidget {
  const LabeledFieldRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.trailingChevron = false,
    this.obscure = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool trailingChevron;
  final bool obscure;

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
            label,
            style: const TextStyle(
              color: kDeviceOverviewLabelColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              textAlign: TextAlign.right,
              style: const TextStyle(color: kDeviceOverviewStatusColor, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: kDeviceOverviewStatusColor, fontSize: 14),
              ),
            ),
          ),
          if (trailingChevron) ...[
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: kDeviceOverviewStatusColor, size: 18),
          ],
        ],
      ),
    );
  }
}
