/// 초기 설정 1차 단계에서 입력받는 보호자 정보.
///
/// Figma "1. 초기 설정" 노트: "1차: 보호자 성명, 관계" — 그래서 필드는 딱 이 두 개뿐이다.
/// [relationship]은 자유 텍스트로 받는다 (부모/조부모/활동지원사 등 케이스가 다양해서
/// 드롭다운으로 미리 못박기보다는 텍스트 입력이 이번 단계에서는 더 유연하다).
class GuardianProfile {
  const GuardianProfile({required this.name, required this.relationship});

  final String name;
  final String relationship;

  factory GuardianProfile.fromMap(Map<String, dynamic> map) {
    return GuardianProfile(
      name: map['name'] as String,
      relationship: map['relationship'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'relationship': relationship};
}
