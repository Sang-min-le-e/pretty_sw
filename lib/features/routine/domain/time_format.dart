/// 서버 형식 `"17:00"`을 화면 표기 "오후 5:00"으로. 형식이 이상하면 받은 값 그대로.
String formatHhmmKorean(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return hhmm;
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? '오전' : '오후';
  return '$period $hour12:${minute.toString().padLeft(2, '0')}';
}

/// 시작~종료 표기. 오전/오후가 같으면 종료 쪽 글자는 뺀다
/// ("오전 9:00~10:00", 다르면 "오전 11:00~오후 12:30").
String formatTimeRangeKorean(String start, String end) {
  if (start.isEmpty) return '';
  final startLabel = formatHhmmKorean(start);
  if (end.isEmpty) return startLabel;
  final endLabel = formatHhmmKorean(end);
  final startPeriod = startLabel.split(' ').first;
  final endParts = endLabel.split(' ');
  final sameDayPart = endParts.length == 2 && endParts.first == startPeriod;
  return '$startLabel~${sameDayPart ? endParts.last : endLabel}';
}
