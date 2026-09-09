/// "루틴 추가" 폼의 "반복" 탭에서 고르는 반복 단위.
enum RepeatUnit { weekly, monthly, yearly, interval }

/// "반복" 탭 설정을 실제 날짜 목록으로 펼쳐주는 순수 함수 모음.
///
/// 이 앱은 반복 규칙 자체를 저장하지 않는다 — 저장/조회 로직
/// (`routinesForDateProvider` 등)이 전부 "특정 날짜의 루틴"만 알면 되게
/// 이미 짜여 있어서, 반복 규칙을 새로 저장하고 매번 펼쳐 보여주는 것보다
/// 저장하는 시점에 미리 날짜별 [Routine]을 여러 개 만들어 저장하는 쪽이
/// 훨씬 간단하다. 그 "날짜 여러 개 만들기"를 담당하는 게 이 파일이다.
///
/// 끝 날짜를 지정하지 않으면([end]가 null) 무한히 반복될 수 있으므로,
/// [horizonDays]로 최대 생성 범위를(기본 1년) [maxOccurrences]로 최대
/// 개수를 제한한다.
class RoutineRecurrence {
  static List<DateTime> weekly({
    required DateTime start,
    required Set<int> weekdays, // 0=일 ... 6=토
    DateTime? end,
    int horizonDays = 365,
    int maxOccurrences = 200,
  }) {
    if (weekdays.isEmpty) return [];
    final limit = end ?? start.add(Duration(days: horizonDays));
    final dates = <DateTime>[];
    var day = DateTime(start.year, start.month, start.day);
    while (!day.isAfter(limit) && dates.length < maxOccurrences) {
      if (weekdays.contains(day.weekday % 7)) dates.add(day);
      day = day.add(const Duration(days: 1));
    }
    return dates;
  }

  static List<DateTime> monthly({
    required DateTime start,
    required int dayOfMonth,
    DateTime? end,
    int horizonDays = 365,
    int maxOccurrences = 60,
  }) {
    final limit = end ?? start.add(Duration(days: horizonDays));
    final dates = <DateTime>[];
    var monthCursor = DateTime(start.year, start.month);
    while (!monthCursor.isAfter(limit) && dates.length < maxOccurrences) {
      final daysInMonth = DateTime(monthCursor.year, monthCursor.month + 1, 0).day;
      final day = DateTime(
        monthCursor.year,
        monthCursor.month,
        dayOfMonth.clamp(1, daysInMonth),
      );
      if (!day.isBefore(DateTime(start.year, start.month, start.day)) &&
          !day.isAfter(limit)) {
        dates.add(day);
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1);
    }
    return dates;
  }

  static List<DateTime> yearly({
    required DateTime start,
    required int month,
    required int day,
    DateTime? end,
    int maxYears = 20,
  }) {
    final dates = <DateTime>[];
    var year = start.year;
    for (var i = 0; i < maxYears; i++) {
      final date = DateTime(year, month, day);
      if (!date.isBefore(DateTime(start.year, start.month, start.day))) {
        if (end != null && date.isAfter(end)) break;
        dates.add(date);
      }
      year++;
    }
    return dates;
  }

  /// "N일/주/개월마다" 형태의 사용자 지정 주기.
  static List<DateTime> interval({
    required DateTime start,
    required int everyN,
    required String unit, // '일' | '주' | '개월'
    DateTime? end,
    int horizonDays = 365,
    int maxOccurrences = 200,
  }) {
    if (everyN <= 0) return [];
    final limit = end ?? start.add(Duration(days: horizonDays));
    final dates = <DateTime>[];
    var day = DateTime(start.year, start.month, start.day);
    while (!day.isAfter(limit) && dates.length < maxOccurrences) {
      dates.add(day);
      day = switch (unit) {
        '주' => day.add(Duration(days: 7 * everyN)),
        '개월' => DateTime(day.year, day.month + everyN, day.day),
        _ => day.add(Duration(days: everyN)),
      };
    }
    return dates;
  }
}
