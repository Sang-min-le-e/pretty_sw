import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 빌드할 때 `--dart-define=API_BASE_URL=http://192.168.0.10:8080/api/v1`처럼
/// 넘기면 그 주소를 쓴다(실기기·다른 사람 PC의 백엔드·배포 서버용). 안 넘기면 빈
/// 글자라서 아래 [resolveApiBaseUrl]이 실행 환경에 맞는 로컬 주소를 고른다.
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// 이 앱이 접속할 백엔드 주소(`docs/API.md` 1-1의 `/api/v1` 베이스).
///
/// 로컬 개발에서는 "백엔드를 띄운 PC"를 가리키는 주소가 실행 환경마다 다르다:
/// - **안드로이드 에뮬레이터**: 에뮬레이터 안에서 `10.0.2.2`가 호스트 PC의
///   `localhost`를 가리키는 특수 주소다.
/// - **iOS 시뮬레이터·데스크톱**: 호스트와 네트워크를 공유해서 `localhost` 그대로.
/// - **실기기(폰)**: `localhost`는 폰 자기 자신이라 안 된다. 폰과 같은 와이파이에
///   있는 PC의 LAN 주소(예: `192.168.0.10`)를 `--dart-define=API_BASE_URL=...`로 넘겨야 한다.
String resolveApiBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
  return 'http://localhost:8080/api/v1';
}

/// 백엔드 API 베이스 클라이언트.
///
/// [getAccessUuid]를 넘기면 모든 요청에 `X-Access-Uuid` 헤더(앱용 인증,
/// `docs/API.md` 1-1)를 자동으로 붙인다 — 로그인 세션이 어디 저장돼
/// 있는지는 이 클래스가 몰라도 되게, 값을 읽어오는 방법만 콜백으로
/// 받는다(실제 연결은 `features/auth/data/auth_providers.dart`가 한다).
class ApiClient {
  ApiClient({String? baseUrl, this.getAccessUuid})
      : dio = Dio(BaseOptions(baseUrl: baseUrl ?? resolveApiBaseUrl())) {
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
