import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS 기본 앱처럼 아래에서 올라오는 휠 시간 선택창(오전/오후 + 시 + 분).
/// "완료"를 누르면 고른 시각을, 바깥을 누르거나 "취소"면 null을 돌려준다.
Future<TimeOfDay?> pickTimeCupertino(BuildContext context, TimeOfDay initial) {
  var selected = initial;
  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (popupContext) => Container(
      height: 300,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(popupContext).pop(),
                  child: const Text('취소', style: TextStyle(color: Color(0xFF7F7F7F))),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.of(popupContext).pop(selected),
                  child: const Text(
                    '완료',
                    style: TextStyle(color: Color(0xFF99B6FF), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
                onDateTimeChanged: (value) =>
                    selected = TimeOfDay(hour: value.hour, minute: value.minute),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 루틴 폼 화면들(추가·수정·할 일 편집)이 같이 쓰는 입력 칸 위젯 모음.
/// 처음에는 추가 폼 파일 안에만 있었는데 수정 화면이 생기면서 공용으로 뺐다.

const kRoutineFormLabelColor = Color(0xFF505050);
const kRoutineFormPlaceholderColor = Color(0xFFA3A3A3);

/// 흰 알약 모양(radius 21) + 옅은 그림자 입력 필드 껍데기. 텍스트필드와
/// 시간 선택 버튼이 똑같은 껍데기를 재사용한다.
class PillField extends StatelessWidget {
  const PillField({
    super.key,
    required this.child,
    this.onTap,
    this.horizontalPadding = 22,
    this.alignment = Alignment.centerLeft,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double horizontalPadding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 55,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
      ),
      alignment: alignment,
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(21), onTap: onTap, child: content);
  }
}

/// 시각 하나를 보여주는 칸(Figma: 112x55, 가운데 정렬). 누르면 부모가 준
/// [onTap]에서 [pickTimeCupertino]를 띄운다. "00:00"(아직 안 고른 기본값)은
/// Figma처럼 옅은 회색, 고른 뒤에는 진한 글자색으로 보여준다.
class TimeField extends StatelessWidget {
  const TimeField({super.key, required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDefault = time.hour == 0 && time.minute == 0;
    return PillField(
      onTap: onTap,
      horizontalPadding: 0,
      alignment: Alignment.center,
      child: Text(
        formatTimeKorean(time),
        style: TextStyle(
          color: isDefault ? kRoutineFormPlaceholderColor : kRoutineFormLabelColor,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// "[00:00] 부터 [00:00] 까지" 한 줄(Figma): 시간 칸 두 개가 112 폭이고 칸 밖
/// 오른쪽에 "부터"/"까지"가 붙는다. 좁은 화면에서는 칸이 줄어든다.
class TimeRangeRow extends StatelessWidget {
  const TimeRangeRow({
    super.key,
    required this.start,
    required this.end,
    required this.onTapStart,
    required this.onTapEnd,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  static const _suffixStyle = TextStyle(color: kRoutineFormPlaceholderColor, fontSize: 16);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: TimeField(time: start, onTap: onTapStart),
          ),
        ),
        const SizedBox(width: 9),
        const SizedBox(width: 32, child: Text('부터', style: _suffixStyle)),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: TimeField(time: end, onTap: onTapEnd),
          ),
        ),
        const SizedBox(width: 9),
        const SizedBox(width: 32, child: Text('까지', style: _suffixStyle)),
      ],
    );
  }
}

/// 화면에 보이는 형식: "오전 5:00", "오후 12:30" (0시는 오전 12시).
String formatTimeKorean(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final period = t.period == DayPeriod.am ? '오전' : '오후';
  return '$period $hour:${t.minute.toString().padLeft(2, '0')}';
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
