/// 서버가 받는 날짜 형식 `yyyy-MM-dd`(`docs/API.md` 1-3 — 시각 없이 날짜만).
/// `padLeft(2, '0')`으로 한 자리 월·일 앞에 0을 붙인다(3월 5일 → "2026-03-05").
String apiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
