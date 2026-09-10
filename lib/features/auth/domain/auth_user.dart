/// 로그인한 보호자 계정 정보. `docs/API.md` 5장(`GET/PATCH /users/me`)과
/// 4장(로그인/회원가입 응답에 포함된 `user`)이 같은 모양을 쓴다.
class AuthUser {
  const AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    this.createdAt,
  });

  final int userId;

  /// `null`이면 아직 온보딩 1차(보호자 성명 입력)를 마치지 않은 계정이다
  /// — 로그인 응답에는 없지만 `GET /users/me`에는 있는 필드라, 로그인
  /// 직후 온보딩 필요 여부를 판단하려면 `GET /users/me`를 한 번 더
  /// 불러야 한다(`docs/API.md` 5장).
  final String? name;

  final String email;

  /// 로그인/회원가입 응답에는 없고 `GET /users/me`에만 있다.
  final DateTime? createdAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as int,
      name: json['name'] as String?,
      email: json['email'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}
