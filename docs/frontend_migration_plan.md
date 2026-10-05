# 프론트엔드-백엔드 연동 마이그레이션 가이드 (Local to API)

이 문서는 `pretty_sw` (프론트엔드/Flutter) 프로젝트가 현재 로컬(Hive)에 의존하고 있는 핵심 기능들을 `2026-khu-artistic-software` (백엔드/Spring Boot) API로 마이그레이션하기 위한 작업 지시서입니다. 순서대로 구현을 진행해 주세요.

---

## 1단계: 회원 탈퇴 API 연동 (워밍업)

현재 프로필 화면의 "탈퇴하기" 버튼은 로컬 데이터만 지우고 로그아웃하는 수준으로 구현되어 있습니다. 백엔드에 완성된 회원 탈퇴 API를 연동하여 완전한 탈퇴가 이루어지도록 합니다.

*   **API 명세:** `DELETE /users/me` (백엔드 `API.md` 참고)
    *   **요청:** 바디 없음. `ApiClient` 인터셉터를 통해 `X-Access-Uuid` 헤더가 자동으로 전송됨.
    *   **응답:** 204 No Content.
    *   **백엔드 동작:** 계정의 `access_uuid` 무효화 및 해당 유저의 자녀, 기기, 루틴 데이터를 모두 일괄 Soft-delete 처리함.
*   **프론트엔드 작업 지시:**
    1.  `features/auth/data/auth_repository.dart` (또는 사용자 관련 리포지토리)에 `deleteUser()` 메서드를 추가하고 Dio를 통해 `DELETE /users/me`를 호출하도록 구현하세요.
    2.  탈퇴 버튼을 누르면 위 API를 먼저 호출합니다.
    3.  API 호출이 성공(204)하면, 기존에 하던 것처럼 로컬 Hive Box(`auth`, `routines`, `profile` 등)를 모두 비웁니다.
    4.  화면을 `/login` (또는 `/splash`)으로 이동시킵니다.

---

## 2단계: 루틴 & 템플릿 로컬 데이터 걷어내고 API 연동 (핵심)

가장 중요한 기능인 루틴과 템플릿이 현재 `Hive` 기반 로컬 리포지토리로 동작 중입니다. 이를 모두 백엔드 API 기반으로 교체해야 합니다.

*   **API 명세:** `API.md` 9장(루틴) 및 10장(루틴 템플릿) 참고
    *   **중요 변경점 (2026-09-09 확정안):** 루틴 반복 생성은 지연 생성이 폐지되었고, `POST /children/:childId/big-routines` 호출 시 반복 날짜만큼 루틴 행을 즉시 생성하여 같은 `series_id`를 부여합니다. 템플릿은 단순한 "저장해둔 양식"으로 취급됩니다.
    *   목록 조회 시에는 한 달치 달력을 통째로 반환하는 API 등을 사용합니다.
*   **프론트엔드 작업 지시:**
    1.  `features/routine/data/` 및 `features/routine_templates/data/` 내부의 `LocalRoutineRepository`, `LocalRoutineTemplateRepository`를 삭제(또는 사용 중지)하고, Dio 기반의 `ApiRoutineRepository`, `ApiRoutineTemplateRepository`를 생성하세요.
    2.  모델 클래스(`domain/`)의 `fromJson`, `toJson` 매핑 로직을 백엔드의 Request/Response 스키마(카멜케이스)에 맞게 수정하세요.
    3.  `*_providers.dart`에서 화면(Screen)들에 주입되는 Provider가 새로 만든 `Api*Repository`를 바라보도록 의존성을 교체하세요.
    4.  루틴 생성/수정/삭제 액션이 발생하면 API 호출 후 `ref.invalidate()`를 사용하여 UI가 서버 데이터를 다시 받아와 갱신되도록 상태 관리를 맞추세요.

---

## 3단계: 기기 (Devices) 온보딩 연동 및 상태 조회 API 연동

현재 온보딩 3차의 기기 연결(Device Connection)은 로컬의 더미(Mock) 데이터를 활용하여 넘어가는 형태로 구현되어 있습니다. 이를 실제 기기 등록 API로 교체해야 합니다.

*   **API 명세:** `API.md` 7장(기기 - 앱용) 참고
    *   **페어링 코드 발급:** `POST /devices/pairing` (온보딩 3차 기기 연결 시작 시점)
    *   기기 조회 및 기타 엔드포인트도 7장에 정의된 대로 사용.
    *   **주의점:** 앱(보호자)이 찌르는 API는 `/api/v1/...` 경로와 `X-Access-Uuid` 헤더를 사용합니다. 기기(워치 등)가 직접 찌르는 `/device-api/v1/...` 경로와 혼동하지 마세요.
*   **프론트엔드 작업 지시:**
    1.  `features/devices/data/` 내부의 로컬 리포지토리를 API 기반으로 교체하세요.
    2.  온보딩 3차 화면(`device-connection` 관련 화면)에서 더미 동작을 제거하고, `POST /devices/pairing`을 호출하여 발급받은 기기 ID(`deviceId`)와 페어링 코드(`pairingCode`)를 UI에 표시 및 처리하세요.
    3.  홈(Home)의 연결된 기기 위젯 및 기기(Devices) 탭 화면이 `GET /devices` (또는 관련 조회 API)를 호출하여 실제 연동된 기기 상태를 보여주도록 수정하세요.
