/// 자녀 한 명. `docs/API.md` 6장(`POST/GET /children`)과 같은 모양.
class Child {
  const Child({
    required this.childId,
    required this.name,
    required this.birthDate,
    required this.relationship,
  });

  final int childId;
  final String name;
  final DateTime birthDate;

  /// `PARENT`(부모) 또는 `ADMIN`(관리자) 둘뿐이다 — 백엔드가 이 두 값으로
  /// 제한해뒀다(`docs/API.md` 6장, 2026-09-04 확정).
  final String relationship;

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      childId: json['childId'] as int,
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      relationship: json['relationship'] as String,
    );
  }
}
