/// 초기 설정 2차 단계에서 입력받는 자녀(피보호자) 정보.
///
/// Figma "1. 초기 설정" 노트: "2차: 자녀 성명, 자녀 생년월일".
/// 생년월일을 받는 이유는 명시돼 있지 않지만, 나이에 맞는 스몰루틴 난이도/문구를
/// 조절하는 데 쓰일 가능성이 높다고 보고 DateTime으로 받아둔다.
class ChildProfile {
  const ChildProfile({required this.name, required this.birthDate});

  final String name;
  final DateTime birthDate;

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      name: map['name'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'birthDate': birthDate.toIso8601String(),
  };
}
