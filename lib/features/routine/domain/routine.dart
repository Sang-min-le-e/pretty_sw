class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.steps,
  });

  final String id;
  final String title;
  final List<String> steps;

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as String,
      title: map['title'] as String,
      steps: List<String>.from(map['steps'] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'steps': steps};
  }
}
