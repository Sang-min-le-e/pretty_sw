/// 나중에 다시 쓸 수 있게 저장해 둔 루틴 틀. 실제 루틴([Routine])과 달리
/// 날짜/시간/대상은 담지 않는다 — "템플릿 사용" 화면(Figma 415:1847)에서
/// 골라서 새 루틴 추가 폼에 이름과 하위 할 일 목록만 미리 채워 넣는 용도.
class RoutineTemplate {
  const RoutineTemplate({
    required this.id,
    required this.title,
    this.steps = const [],
  });

  final String id;
  final String title;
  final List<String> steps;

  factory RoutineTemplate.fromMap(Map<String, dynamic> map) {
    return RoutineTemplate(
      id: map['id'] as String,
      title: map['title'] as String,
      steps: List<String>.from(map['steps'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'steps': steps};
  }
}
