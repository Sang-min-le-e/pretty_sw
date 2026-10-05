import '../../../core/network/api_date.dart';

/// 서버가 날짜를 펼치는 방식(`POST /children/:childId/big-routines`의
/// `repeatType`, `docs/API.md` 9장). 셋 중 하나만 고른다.
enum RepeatType {
  /// 기간 안의 매일(하루짜리는 시작일과 종료일을 같게).
  range('RANGE'),

  /// 기간 안에서 지정한 요일마다.
  weekly('WEEKLY'),

  /// 지정한 날짜들만(최대 [maxRepeatDates]개).
  dates('DATES');

  const RepeatType(this.code);
  final String code;
}

/// `DATES` 모드에서 서버가 받는 날짜 개수의 상한.
const maxRepeatDates = 12;

/// 새 루틴을 만들 때 서버로 보내는 요청 내용. 화면의 폼 값을 서버 규칙에 맞게
/// 모아 둔 것이라, 반복 모드마다 쓰는 필드가 다르다(안 쓰는 필드는 비워 둔다).
class NewRoutine {
  const NewRoutine({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.repeatType,
    this.startDate,
    this.endDate,
    this.repeatDays = const [],
    this.repeatDates = const [],
    required this.steps,
  });

  final String title;

  /// `"07:30"` 형식. 종료는 시작보다 뒤여야 한다(서버가 검사).
  final String startTime;
  final String endTime;

  final RepeatType repeatType;

  /// `range`·`weekly`에서 필수.
  final DateTime? startDate;
  final DateTime? endDate;

  /// `weekly`에서 필수. `MON`~`SUN`.
  final List<String> repeatDays;

  /// `dates`에서 필수.
  final List<DateTime> repeatDates;

  /// 하위 할 일 이름들. 서버가 이 순서(`order` 1, 2, 3…)로 줄 세운다.
  final List<String> steps;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'repeatType': repeatType.code,
      if (startDate != null) 'startDate': apiDate(startDate!),
      if (endDate != null) 'endDate': apiDate(endDate!),
      if (repeatType == RepeatType.weekly) 'repeatDays': repeatDays,
      if (repeatType == RepeatType.dates)
        'repeatDates': [for (final d in repeatDates) apiDate(d)],
      'smallRoutines': [
        for (var i = 0; i < steps.length; i++) {'title': steps[i], 'order': i + 1},
      ],
    };
  }
}
