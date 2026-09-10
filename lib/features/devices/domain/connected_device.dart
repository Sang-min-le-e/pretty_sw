/// 이 가디언 계정에 연결된 자녀 기기 하나를 나타내는 도메인 모델.
///
/// 홈 화면의 "연결된 기기" 카드(`ConnectedDevicesCard`, node 392:5304)와
/// "연결된 기기" 화면(node 392:5220)이 보여주는 목록의 원소다. 실제 BLE
/// 페어링이 아직 연결돼 있지 않아서([core/ble/ble_service.dart] 참고),
/// 지금은 "기기 추가하기"/"연결 기기 추가" 흐름에서 이름만 받아 저장한다.
class ConnectedDevice {
  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.connectedAt,
  });

  final String id;

  /// 기기 주인의 짧은 이름(예: "지예"). 화면마다 접미사를 다르게 붙여서
  /// 보여준다 — 홈/상세 화면 제목은 "지예의 기기", 목록 한 줄은
  /// "지예님의 기기"처럼. "기기 추가하기"(BLE 페어링) 흐름에서 이 이름을
  /// 직접 입력받는다.
  final String name;

  /// 연결(등록)된 시각. 목록을 등록 순서대로 보여줄 때와, 아이콘/점 색을
  /// 순서대로 순환시켜 배정할 때(`deviceAccentFor` 참고) 함께 쓰인다.
  final DateTime connectedAt;

  factory ConnectedDevice.fromMap(Map<String, dynamic> map) {
    return ConnectedDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      connectedAt: DateTime.parse(map['connectedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }
}
