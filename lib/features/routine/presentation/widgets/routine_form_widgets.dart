import 'package:flutter/material.dart';

/// 루틴 폼 화면들(추가·수정·할 일 편집)이 같이 쓰는 입력 칸 위젯 모음.
/// 처음에는 추가 폼 파일 안에만 있었는데 수정 화면이 생기면서 공용으로 뺐다.

const kRoutineFormLabelColor = Color(0xFF505050);
const kRoutineFormPlaceholderColor = Color(0xFFA3A3A3);

/// 흰 알약 모양(radius 21) + 옅은 그림자 입력 필드 껍데기. 텍스트필드와
/// 시간 선택 버튼이 똑같은 껍데기를 재사용한다.
class PillField extends StatelessWidget {
  const PillField({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(21), onTap: onTap, child: content);
  }
}

/// "00:00 부터" / "00:00 까지"처럼 시각 + 안내 글자가 함께 붙은 시간
/// 선택 버튼. 누르면 부모가 준 [onTap]에서 표준 [showTimePicker]를 띄운다.
class TimeField extends StatelessWidget {
  const TimeField({super.key, required this.time, required this.suffix, required this.onTap});

  final TimeOfDay time;
  final String suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return PillField(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kRoutineFormLabelColor, fontSize: 16)),
          Text(suffix, style: const TextStyle(color: kRoutineFormPlaceholderColor, fontSize: 16)),
        ],
      ),
    );
  }
}

/// `TimeOfDay`를 서버 형식 `"07:30"`으로.
String formatHhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 서버 형식 `"07:30"`을 `TimeOfDay`로. 비었거나 형식이 이상하면 [fallback].
TimeOfDay parseHhmm(String? value, {TimeOfDay fallback = const TimeOfDay(hour: 0, minute: 0)}) {
  final parts = (value ?? '').split(':');
  if (parts.length != 2) return fallback;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return fallback;
  return TimeOfDay(hour: h, minute: m);
}
