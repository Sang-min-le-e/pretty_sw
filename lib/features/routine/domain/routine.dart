/// 루틴 하나(예: "11:00 교무실 가기")를 나타내는 도메인 모델.
///
/// Figma의 "1. 일정 탭 첫 화면"(node 392:1740)에서, 달력에서 선택한 날짜
/// 아래에 나열되는 카드 한 장 = 루틴 한 개다. 여러 단계로 이뤄진 루틴은
/// [steps]가 "급식실 가기 → 배식 받기"처럼 번호가 매겨진 하위 할 일
/// 목록으로 카드 안에 항상 펼쳐져 보인다.
class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.tag,
    this.steps = const [],
    this.participants = const [],
  });

  final String id;

  /// 루틴 이름. 카드에는 시간과 함께 "11:00 교무실 가기"처럼 표시된다.
  final String title;

  /// 루틴이 속한 날짜(연/월/일)와 시작 시각(시/분)을 하나로 합쳐서 저장한다.
  /// 달력에서 "이 날짜에 루틴이 있는지"를 확인할 땐 연/월/일만 보고,
  /// 카드 목록을 시간순으로 정렬/표시할 땐 시/분을 함께 쓴다.
  final DateTime dateTime;

  /// 카드에 "・공통" 또는 "・지예님의 기기"처럼 붙는 꼬리표.
  /// 이 루틴을 모든 기기가 공유하는지, 특정 기기 하나만 쓰는지를 나타낸다.
  final String tag;

  /// 카드를 펼쳤을 때 보이는 하위 할 일 목록(순서대로 번호가 매겨진다).
  /// 비어 있으면 카드에 펼침 화살표(›) 없이 시간/제목/꼬리표만 보여준다.
  final List<String> steps;

  /// 이 루틴을 수행하는 가족 구성원과, 각자 완료했는지 여부.
  /// Figma "3. 단일루틴 상세보기"(node 392:2096) 화면에서 원형 진행률
  /// (완료 인원 수 / 전체 인원 수)과 완료·미완료 아바타 목록을 그리는 데
  /// 쓰인다. "・공통" 루틴은 가족 구성원 전체가, "・OO님의 기기" 루틴은
  /// 해당 구성원 한 명만 들어간다.
  final List<RoutineParticipant> participants;

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as String,
      title: map['title'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      tag: map['tag'] as String,
      steps: List<String>.from(map['steps'] as List? ?? const []),
      participants: (map['participants'] as List? ?? const [])
          .map((raw) => RoutineParticipant.fromMap(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'tag': tag,
      'steps': steps,
      'participants': participants.map((p) => p.toMap()).toList(),
    };
  }
}

/// [Routine.participants]의 원소 하나. 이름과 완료 여부만 저장한다 —
/// 아이콘 색깔 등 화면에 그릴 때 필요한 스타일은
/// `routine_detail_screen.dart`의 [FamilyMemberStyle]이 이름으로 찾아준다.
class RoutineParticipant {
  const RoutineParticipant({required this.name, required this.completed});

  final String name;
  final bool completed;

  factory RoutineParticipant.fromMap(Map<String, dynamic> map) {
    return RoutineParticipant(
      name: map['name'] as String,
      completed: map['completed'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'completed': completed};
  }
}
