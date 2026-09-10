import 'package:dio/dio.dart';

/// 로컬 개발 기본 주소. 안드로이드 에뮬레이터 안에서 `10.0.2.2`는 이
/// 머신(호스트 PC)의 `localhost`를 가리키는 특수 주소라, PC에서
/// `./gradlew bootRun`으로 띄운 백엔드(기본 포트 8080, `docs/API.md` 1-1의
/// `/api/v1` 베이스)에 에뮬레이터에서 접속하려면 이 주소를 써야 한다.
/// 실기기·배포 서버를 쓸 땐 [ApiClient]를 만들 때 `baseUrl`을 바꿔서 넘기면 된다.
const defaultApiBaseUrl = 'http://10.0.2.2:8080/api/v1';

/// 백엔드 API 베이스 클라이언트.
///
/// [getAccessUuid]를 넘기면 모든 요청에 `X-Access-Uuid` 헤더(앱용 인증,
/// `docs/API.md` 1-1)를 자동으로 붙인다 — 로그인 세션이 어디 저장돼
/// 있는지는 이 클래스가 몰라도 되게, 값을 읽어오는 방법만 콜백으로
/// 받는다(실제 연결은 `features/auth/data/auth_providers.dart`가 한다).
class ApiClient {
  ApiClient({String baseUrl = defaultApiBaseUrl, this.getAccessUuid})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    final getUuid = getAccessUuid;
    if (getUuid != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final uuid = await getUuid();
            if (uuid != null) {
              options.headers['X-Access-Uuid'] = uuid;
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio dio;
  final Future<String?> Function()? getAccessUuid;
}
