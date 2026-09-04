import 'package:dio/dio.dart';

/// 백엔드 API 베이스 클라이언트. baseUrl은 백엔드 파트와 스펙 확정되면 채운다.
class ApiClient {
  ApiClient({String baseUrl = ''})
      : dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio dio;
}
