/// 워치 화면 속에서 자란다는 그 "캐릭터".
///
/// Figma 컨셉 메모: "미션 성공 -> 화면 속 캐릭터 성장 or 무작위 선물 뽑아줌".
/// 실제 캐릭터 그래픽/성장 단계별 이미지는 디자인팀의 "캐릭터, 먹이 레퍼런스"
/// 무드보드 단계라 아직 구체 스펙이 없다. 그래서 여기서는 그 보상 구조를
/// 숫자 두 개로만 단순하게 표현해뒀다:
///  - [feedCount]: 지금까지 몇 번 "먹이"를 줬는지(=스몰루틴을 몇 번 완료했는지)
///  - [growthStage]: feedCount가 일정 수를 넘을 때마다 하나씩 올라가는 성장 단계
///
/// 나중에 실제 캐릭터 디자인이 나오면, growthStage 값에 맞는 이미지/애니메이션을
/// 매핑해주는 위젯만 새로 만들면 되고 이 모델 자체는 안 바뀌어도 될 것이다.
class CompanionCharacter {
  const CompanionCharacter({this.feedCount = 0});

  final int feedCount;

  /// 먹이 5번마다 한 단계씩 성장한다고 임시로 정해뒀다.
  /// (기획에 구체적인 성장 곡선이 없어서, 데모에서 성장하는 느낌을 보여줄 수 있는
  /// 정도의 값으로 잡은 것 — 실제 밸런스는 기획/디자인이 정해지면 바꾸면 된다.)
  static const feedsPerGrowthStage = 5;

  int get growthStage => feedCount ~/ feedsPerGrowthStage;

  CompanionCharacter feed() => CompanionCharacter(feedCount: feedCount + 1);

  factory CompanionCharacter.fromMap(Map<String, dynamic> map) {
    return CompanionCharacter(feedCount: map['feedCount'] as int? ?? 0);
  }

  Map<String, dynamic> toMap() => {'feedCount': feedCount};
}
