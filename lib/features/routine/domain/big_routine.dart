import 'package:flutter/material.dart' show TimeOfDay;

import 'small_routine.dart';

/// 빅루틴(BigRoutine) — "루틴 등록" 기획의 최상위 단위.
///
/// 피그마 "앱 초안"의 실제 화면 목업(오늘 할 일 / 루틴 추가 팝업)을 기준으로 다시 짰다.
/// 처음에는 텍스트 기획 메모만 보고 "연속 날짜 범위(16일~20일 같은)"로 만들었는데,
/// 실제 목업의 "루틴 추가" 팝업을 보니 반복 방식이 그게 아니라 **요일 반복**이었다
/// (고정 루틴 토글을 켜면 일/월/화/수/목/금/토 중 반복할 요일을 고르는 UI가 나옴).
/// 그래서 [date] + [isRecurring] + [recurringWeekdays] 조합으로 바꿨다:
///  - 고정 루틴이 아니면: [date] 하루에만 적용된다.
///  - 고정 루틴이면: [date] 이후로, [recurringWeekdays]에 포함된 요일마다 계속 적용된다.
///
/// [isSent]는 목업에서 본 "전송하시겠습니까? 한 번 전송한 루틴은 수정할 수 없습니다"
/// 팝업과 연결된 값이다. 워치로 한 번 전송(=하루의 루틴을 확정)하고 나면 그 날의
/// 루틴들은 더 이상 수정/삭제가 안 되게 잠긴다 — 대상 사용자에게 하루 중간에
/// 일정이 바뀌는 혼란을 주지 않으려는 의도로 보여서 그대로 반영했다.
class BigRoutine {
  const BigRoutine({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.smallRoutines,
    this.isRecurring = false,
    this.recurringWeekdays = const {},
    this.isSent = false,
  });

  final String id;
  final String title;

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// 이 빅루틴이 "만들어진" 기준 날짜. 반복이 아니면 이 날짜에만 나타나고,
  /// 반복이면 이 날짜부터 시작해서 반복 요일마다 나타난다.
  final DateTime date;

  final bool isRecurring;

  /// DateTime.weekday 값(월=1 ... 일=7) 집합.
  final Set<int> recurringWeekdays;

  final bool isSent;

  final List<SmallRoutine> smallRoutines;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 캘린더/오늘 할 일 화면에서 "이 날짜에 이 빅루틴을 보여줘야 하나?"를 판단한다.
  bool appliesOn(DateTime target) {
    final day = _dateOnly(target);
    final anchor = _dateOnly(date);
    if (!isRecurring) return day == anchor;
    if (day.isBefore(anchor)) return false;
    return recurringWeekdays.contains(day.weekday);
  }

  /// 지금 이 순간(현재 시각)이 이 빅루틴의 시간 범위 안에 있는지.
  /// 홈 화면의 "현재 루틴 진행중" 카드에 쓰인다.
  bool isActiveAt(DateTime now) {
    if (!appliesOn(now)) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  double get completionRate {
    if (smallRoutines.isEmpty) return 0;
    final doneCount = smallRoutines.where((s) => s.isDone).length;
    return doneCount / smallRoutines.length;
  }

  BigRoutine copyWith({
    String? title,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isRecurring,
    Set<int>? recurringWeekdays,
    bool? isSent,
    List<SmallRoutine>? smallRoutines,
  }) {
    return BigRoutine(
      id: id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringWeekdays: recurringWeekdays ?? this.recurringWeekdays,
      isSent: isSent ?? this.isSent,
      smallRoutines: smallRoutines ?? this.smallRoutines,
    );
  }

  factory BigRoutine.fromMap(Map<String, dynamic> map) {
    return BigRoutine(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: _timeFromMinutes(map['startTimeMinutes'] as int),
      endTime: _timeFromMinutes(map['endTimeMinutes'] as int),
      date: DateTime.parse(map['date'] as String),
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringWeekdays: Set<int>.from(map['recurringWeekdays'] as List? ?? const []),
      isSent: map['isSent'] as bool? ?? false,
      smallRoutines: (map['smallRoutines'] as List)
          .map((raw) => SmallRoutine.fromMap(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTimeMinutes': startTime.hour * 60 + startTime.minute,
      'endTimeMinutes': endTime.hour * 60 + endTime.minute,
      'date': _dateOnly(date).toIso8601String(),
      'isRecurring': isRecurring,
      'recurringWeekdays': recurringWeekdays.toList(),
      'isSent': isSent,
      'smallRoutines': smallRoutines.map((s) => s.toMap()).toList(),
    };
  }

  static TimeOfDay _timeFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}
