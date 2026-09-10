/// 알림 벨 뱃지 숫자의 근거가 되는 알림 한 건.
///
/// 아직 알림 목록/상세 화면이 없어서(홈 화면 벨 아이콘을 눌러도 반응이
/// 없다, `home_screen.dart` 참고) 지금은 "몇 건 있는지"만 의미가 있다.
/// `Notification`이라는 이름은 Flutter의 스크롤 알림(`ScrollNotification`
/// 등)과 헷갈릴 수 있어서 `AppNotification`으로 지었다.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
