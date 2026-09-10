import 'package:dio/dio.dart';

/// 백엔드 공통 에러 응답(`docs/API.md` 2-2)을 앱 코드에서 다루기 쉬운
/// 예외 하나로 바꾼 것. `code`로 분기하고 `message`는 그대로 사용자에게
/// 보여주면 된다(백엔드가 이미 한국어 사용자 노출용 문구로 채워준다).
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

/// [DioException]을 [ApiException]으로 변환한다. 서버가 공통 envelope로
/// 응답했으면 그 안의 `code`/`message`를 그대로 쓰고, 서버에 아예 닿지
/// 못했으면(연결 거부·타임아웃 등 — 백엔드를 안 띄웠을 때 가장 흔하다)
/// `NETWORK_ERROR`로 감싼다.
Never throwAsApiException(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] is Map) {
    final error = data['error'] as Map;
    throw ApiException(
      code: error['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error['message'] as String? ?? '알 수 없는 오류가 발생했어요.',
      statusCode: e.response?.statusCode,
    );
  }
  throw ApiException(
    code: 'NETWORK_ERROR',
    message: '서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.',
    statusCode: e.response?.statusCode,
  );
}
