/// 기기에서 할 일을 완료했다는 알림 한 건. 홈 화면 벨 뱃지는 아직 읽지 않은
/// ([read]가 false인) 알림 수이고, 벨을 누르면 알림 목록 화면이 열린다.
/// `Notification`이라는 이름은 Flutter의 스크롤 알림(`ScrollNotification`
/// 등)과 헷갈릴 수 있어서 `AppNotification`으로 지었다.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.createdAt,
    this.title = '',
    this.read = false,
  });

  final String id;
  final String message;
  final DateTime createdAt;

  /// 카드 윗줄(예: "완료 알림"). 이전 버전에 저장된 알림에는 없어서 빈 문자열일 수 있다.
  final String title;
  final bool read;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      title: map['title'] as String? ?? '',
      read: map['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'read': read,
    };
  }
}
