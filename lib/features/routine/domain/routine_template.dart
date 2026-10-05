/// 자주 쓰는 루틴을 저장해 둔 양식(`docs/API.md` 10장). 자녀별로 서버에
/// 저장되고, 날짜·반복은 담지 않는다 — "템플릿 사용" 화면에서 하나를 고르면
/// 새 루틴 추가 폼에 이름·시간·하위 할 일이 미리 채워지고, 날짜와 반복은
/// 그 폼에서 새로 고른다. 서버는 양식을 꺼내 쓸 때 값을 **복사**하므로 양식을
/// 나중에 고쳐도 이미 만든 루틴은 바뀌지 않는다.
class RoutineTemplate {
  const RoutineTemplate({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.steps = const [],
  });

  /// 서버의 `templateId`.
  final int id;
  final String title;

  /// `"07:30"` 형식. 서버가 시각을 비워 둘 수 있어 없으면 빈 문자열.
  final String startTime;
  final String endTime;

  /// 하위 할 일 이름들(서버가 준 `order` 순).
  final List<String> steps;

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) {
    final smalls = (json['smallRoutines'] as List? ?? const [])
        .map((raw) => raw as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => ((a['order'] as int?) ?? 0).compareTo((b['order'] as int?) ?? 0));
    return RoutineTemplate(
      id: json['templateId'] as int,
      title: json['title'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      steps: [for (final s in smalls) s['title'] as String],
    );
  }
}
