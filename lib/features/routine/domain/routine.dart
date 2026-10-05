/// 루틴 하나(예: "07:30~08:30 아침 준비")를 나타내는 도메인 모델. 서버
/// 용어로는 **빅루틴 하루치**다 — 서버는 반복 루틴을 날짜별 행으로 미리 만들어
/// 두기 때문에(`docs/API.md` 9장), 같은 반복에서 나온 행들은 [seriesId]가 같고
/// 날짜([date])만 다르다.
///
/// 루틴 안의 하위 할 일은 [smallRoutines]다. 완료 여부는 루틴이 아니라 이
/// 할 일마다 있다(`PENDING`/`DONE`) — 아이가 기기에서 할 일을 완료하면 서버에
/// 올라가고, 앱은 읽기만 한다.
class Routine {
  const Routine({
    required this.id,
    required this.seriesId,
    required this.date,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.smallRoutines = const [],
  });

  /// 서버의 `bigRoutineId`.
  final int id;

  /// 같은 반복으로 만들어진 루틴들을 묶는 값.
  final String seriesId;

  /// 이 루틴이 속한 날짜. 시각은 0시로 고정(날짜만 의미가 있다).
  final DateTime date;

  final String title;

  /// `"07:30"` 형식(`HH:mm`). 서버가 시각을 비워 둔 루틴이 올 수도 있어서
  /// 없으면 빈 문자열이다.
  final String startTime;
  final String endTime;

  /// 하위 할 일. 서버가 `sortOrder` 순으로 준다. 단일 루틴이어도 할 일 1개
  /// (제목과 같은 이름)를 갖는다 — 완료 여부가 할 일에 붙기 때문이다.
  final List<SmallRoutine> smallRoutines;

  int get totalCount => smallRoutines.length;
  int get doneCount => smallRoutines.where((s) => s.done).length;

  /// 카드 한 줄에 쓰는 시간 표기. 종료 시각이 있으면 "07:30~08:30".
  String get timeLabel {
    if (startTime.isEmpty) return '';
    return endTime.isEmpty ? startTime : '$startTime~$endTime';
  }

  /// 날짜와 시작 시각을 합친 값(정렬·기간 비교용). 시작 시각이 없으면 0시.
  DateTime get startDateTime {
    final parts = startTime.split(':');
    if (parts.length != 2) return date;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  /// `GET /children/:childId/calendar` 응답의 `bigRoutines` 원소 하나를
  /// [date](그 날짜 항목의 `date`)와 함께 모델로 바꾼다.
  factory Routine.fromCalendarJson(DateTime date, Map<String, dynamic> json) {
    final smalls = (json['smallRoutines'] as List? ?? const [])
        .map((raw) => SmallRoutine.fromJson(raw as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Routine(
      id: json['bigRoutineId'] as int,
      seriesId: json['seriesId'] as String? ?? '',
      date: date,
      title: json['title'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      smallRoutines: smalls,
    );
  }
}

/// 루틴 안의 하위 할 일 하나(예: "세수하기"). [done]은 서버의
/// `status == 'DONE'`이다.
class SmallRoutine {
  const SmallRoutine({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.done,
  });

  final int id;
  final String title;
  final int sortOrder;
  final bool done;

  factory SmallRoutine.fromJson(Map<String, dynamic> json) {
    return SmallRoutine(
      id: json['smallRoutineId'] as int,
      title: json['title'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      done: json['status'] == 'DONE',
    );
  }
}
