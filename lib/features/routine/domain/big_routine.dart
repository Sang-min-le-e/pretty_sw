import 'package:flutter/material.dart' show TimeOfDay;

import 'small_routine.dart';

/// 빅루틴(BigRoutine) — "루틴 등록" 기획의 최상위 단위.
///
/// Figma 기획 노트(2번, "루틴 등록") 요약:
///  1) 시간 범위를 가질 수 있다 (ex: 8:00~12:00) → [startTime]/[endTime]
///  2) 두 가지 설정값이 있다고 적혀 있었다.
///     - 설정값1 "고정 빅루틴": 앞으로 루틴을 등록할 때 이 빅루틴이 디폴트로 생성되고,
///       내부 스몰루틴들도 자동으로 디폴트가 되는 템플릿 개념 → [isFixedDefault]
///     - 설정값2 "날짜 선택 / 연속적 날짜 선택" (ex: 16일~20일): 특정 하루에만 적용될 수도
///       있고, 연속된 날짜 범위에 반복 적용될 수도 있다 → [startDate]/[endDate]
///       (하루짜리면 startDate == endDate로 표현한다.)
///  3) 내부에 여러 개의 스몰루틴(순서가 있는 할 일)을 담는다 → [smallRoutines]
///
/// "고정 빅루틴이 등록될 때 자동으로 디폴트 생성된다"는 동작까지는 백엔드 동기화
/// 스펙이 아직 없어서(팀 백엔드 파트와 API 계약이 확정되면) 이번 스캐폴딩에는
/// 안 넣었다. 지금은 [isFixedDefault] 플래그만 두고, 실제로 "다음 날짜에도
/// 자동 복사"하는 로직은 백엔드 연동 단계에서 채워 넣으면 된다.
class BigRoutine {
  const BigRoutine({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.smallRoutines,
    this.isFixedDefault = false,
  });

  final String id;
  final String title;

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// 날짜는 시:분 정보 없이 "연/월/일"만 의미가 있어야 비교가 쉬워진다.
  /// (DateTime에는 시분초가 딸려오므로, 저장/비교할 때 [_dateOnly]로 한 번 걸러준다.)
  final DateTime startDate;
  final DateTime endDate;

  final bool isFixedDefault;

  final List<SmallRoutine> smallRoutines;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 캘린더에서 특정 날짜를 클릭했을 때 "이 날짜에 보여줘야 할 빅루틴인지" 판단하는 함수.
  /// startDate ~ endDate 사이(양 끝 포함)에 있으면 true.
  bool appliesOn(DateTime date) {
    final target = _dateOnly(date);
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  /// 이번 빅루틴의 "미션 이행률" — 내부 스몰루틴 중 완료된 비율.
  /// 대시보드(메인창)의 "이번주 미션 이행률" 계산에 쓰인다.
  double get completionRate {
    if (smallRoutines.isEmpty) return 0;
    final doneCount = smallRoutines.where((s) => s.isDone).length;
    return doneCount / smallRoutines.length;
  }

  BigRoutine copyWith({
    String? title,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFixedDefault,
    List<SmallRoutine>? smallRoutines,
  }) {
    return BigRoutine(
      id: id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFixedDefault: isFixedDefault ?? this.isFixedDefault,
      smallRoutines: smallRoutines ?? this.smallRoutines,
    );
  }

  factory BigRoutine.fromMap(Map<String, dynamic> map) {
    return BigRoutine(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: _timeFromMinutes(map['startTimeMinutes'] as int),
      endTime: _timeFromMinutes(map['endTimeMinutes'] as int),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      isFixedDefault: map['isFixedDefault'] as bool? ?? false,
      smallRoutines: (map['smallRoutines'] as List)
          .map((raw) => SmallRoutine.fromMap(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      // TimeOfDay는 그 자체로 직렬화가 안 되므로 "자정부터 몇 분 지났는지"
      // 정수 하나로 바꿔서 저장한다. (예: 8:30 -> 8*60+30 = 510)
      'startTimeMinutes': startTime.hour * 60 + startTime.minute,
      'endTimeMinutes': endTime.hour * 60 + endTime.minute,
      'startDate': _dateOnly(startDate).toIso8601String(),
      'endDate': _dateOnly(endDate).toIso8601String(),
      'isFixedDefault': isFixedDefault,
      'smallRoutines': smallRoutines.map((s) => s.toMap()).toList(),
    };
  }

  static TimeOfDay _timeFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}
