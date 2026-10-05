# Tomo 프론트엔드 코드 구조 가이드

이 문서는 `lib/` 아래 코드를 처음 보거나 오랜만에 다시 볼 때, **어디에 무엇이 있고 무엇을 고치려면 어디를 열어야 하는지** 빠르게 찾기 위한 지도다.
(기준: 2026-10-05, 커밋 `8973ead` 시점 / Dart 파일 70개, 8,854줄)

---

## 1. 한눈에 보기

| 항목 | 사용 기술 | 어디서 |
|---|---|---|
| UI 프레임워크 | Flutter (Material 3) | 전체 |
| 화면 이동 | `go_router` | `lib/app/router.dart` |
| 상태 관리 | `flutter_riverpod` 3.x | 각 기능의 `data/*_providers.dart` |
| 로컬 저장 | `hive` / `hive_flutter` | `lib/core/storage/local_storage_service.dart` |
| 서버 통신 | `dio` | `lib/core/network/api_client.dart` |
| 블루투스 | `flutter_reactive_ble` (스캔만 동작) | `lib/core/ble/ble_service.dart` |
| 아이콘/로고 | `flutter_svg` + `assets/images/*.svg` (Figma에서 추출) | 각 화면 |
| 기타 | `image_picker`, `path_provider` (프로필 사진) | `features/profile/data/` |

`pubspec.yaml`에 있지만 **아직 코드 어디에서도 쓰지 않는** 패키지: `flutter_tts`, `flutter_local_notifications`.

---

## 2. 폴더 구조

```
lib/
├── main.dart                  # 앱 시작점: Hive 초기화 → ProviderScope로 RoutineApp 실행
├── app/                       # 앱 전체에 걸친 설정
│   ├── app.dart               # MaterialApp.router (테마 + 라우터 연결)
│   ├── router.dart            # ★ 모든 화면 경로(URL) 목록. 화면 추가 시 반드시 여기 등록
│   ├── theme.dart             # 큰 글씨·큰 버튼 기본 테마
│   └── widgets/               # 여러 기능이 같이 쓰는 공용 위젯
│       ├── bottom_nav_bar.dart    # 하단 탭바 (홈/루틴/기기/내 정보)
│       ├── back_header.dart       # "‹ 제목" 상단 바
│       ├── pairing_glow.dart      # 기기 찾는 중 확산광 효과
│       └── progress_ring.dart     # 원형 진행률 게이지
├── core/                      # 기능과 무관한 기반 코드 (화면 없음)
│   ├── network/
│   │   ├── api_client.dart        # Dio + X-Access-Uuid 헤더 자동 첨부
│   │   └── api_exception.dart     # 서버 에러 → ApiException 변환
│   ├── storage/local_storage_service.dart   # Hive.openBox 얇은 래퍼
│   └── ble/ble_service.dart       # BLE 스캔/연결 (UUID 미정)
└── features/                  # 기능 단위 폴더 (아래 3장 참고)
    ├── splash/        # 시작 로고
    ├── auth/          # 로그인, 세션(accessUuid), 내 계정 정보  ← 서버 연동
    ├── onboarding/    # 최초 로그인 3단계 설정
    ├── children/      # 자녀 등록                                ← 서버 연동
    ├── home/          # 홈 탭
    ├── routine/       # 루틴 탭 (달력, 추가/수정, 템플릿)         ← 로컬(Hive)
    ├── devices/       # 기기 탭, 연결된 기기                      ← 로컬(Hive)
    ├── profile/       # 내 정보 탭, 프로필 사진                   ← 로컬 + 서버
    ├── notifications/ # 홈 벨 뱃지 개수 (데이터 넣는 곳 아직 없음)
    └── watch_connection/ # BLE 스캔 화면 (진입 경로 없음)
```

---

## 3. 기능 폴더 안의 3층 구조

각 `features/<기능>/` 폴더는 필요한 것만 아래 세 층을 가진다.

```
features/routine/
├── presentation/   화면(위젯). 사용자가 보는 것. provider만 바라본다.
│   └── widgets/    그 기능 안에서만 쓰는 작은 위젯
├── data/           저장소(Repository) + provider. "데이터를 어디서 어떻게 가져오나"
└── domain/         순수 데이터 모델 (Routine 등). toMap/fromMap 또는 fromJson
```

**데이터가 흐르는 방향 (예: 루틴 저장)**

```
AddRoutineScreen (presentation)
   │ ref.read(routineActionsProvider).addRoutine(routine)
   ▼
RoutineActions (data/routine_providers.dart)
   │ ① repository.saveRoutine(routine)
   │ ② ref.invalidate(routineListProvider)   ← "목록 캐시 버려!"
   ▼
LocalRoutineRepository (data/routine_repository.dart)
   │ box.put(routine.id, routine.toMap())
   ▼
Hive 박스 'routines'

   ② 때문에 routineListProvider를 watch하던 모든 provider/화면
   (routinesForDateProvider → 달력, 오늘 할 일, 홈 "현재 루틴" 등)이 자동으로 다시 그려진다.
```

이 **"Actions 클래스가 저장 → invalidate"** 패턴이 routine / routine template / devices / avatar 에서 똑같이 반복된다. 새 기능도 이 모양을 따르면 된다.

### provider 종류 빠른 참고

| 종류 | 언제 쓰나 | 이 프로젝트 예 |
|---|---|---|
| `Provider` | 객체 하나 만들어 공유 (저장소, Actions) | `routineRepositoryProvider`, `deviceActionsProvider` |
| `FutureProvider` | 비동기로 한 번 불러와 캐싱 | `routineListProvider`, `currentUserProvider` |
| `Provider.family` | 인자(날짜, id)별로 다른 결과 | `routinesForDateProvider(date)`, `routineByIdProvider(id)` |
| `StateProvider` | 화면 간 공유하는 단순 값 | `selectedDeviceIndexProvider` (홈 캐러셀 위치) |
| `StreamProvider` | 계속 흘러오는 값 | `watchScanProvider` (BLE 스캔) |

화면에서는 `ref.watch(...)` = 값이 바뀌면 다시 그림, `ref.read(...)` = 버튼 눌렀을 때 한 번만 사용.

---

## 4. 앱 실행 흐름

```
main.dart  Hive.initFlutter()
   ▼
app.dart   MaterialApp.router(theme, appRouter)
   ▼
/splash    타이머 후 → context.go('/login')        (자동 로그인 없음: 항상 로그인 화면을 지난다)
   ▼
/login     _submit():
           1) POST /auth/login   → accessUuid를 Hive 'auth' 박스에 저장
           2) GET  /users/me     → name 확인
              ├─ name == null → /onboarding/guardian-info  (PATCH /users/me)
              │                   → /onboarding/child-info  (POST /children)
              │                   → /onboarding/device-connection (로컬, BLE 미연동)
              │                   → /
              └─ name 있음     → /  (홈)
```

이후 모든 API 요청에는 `ApiClient`의 인터셉터가 Hive에 저장된 `X-Access-Uuid`를 자동으로 붙인다
(연결 지점: `features/auth/data/auth_providers.dart`의 `apiClientProvider`).

---

## 5. 데이터는 어디에 저장되나

### 5-1. 로컬 (Hive 박스)

| 박스 이름 | 키 | 담는 것 | 저장소 클래스 |
|---|---|---|---|
| `auth` | `access_uuid` | 로그인 세션 값 `{value: uuid}` | `LocalAuthSessionRepository` |
| `routines` | 루틴 id | `Routine.toMap()` | `LocalRoutineRepository` |
| `routine_templates` | 템플릿 id | `RoutineTemplate.toMap()` | `LocalRoutineTemplateRepository` |
| `devices` | 기기 id | `ConnectedDevice.toMap()` | `LocalDeviceRepository` |
| `profile` | `avatar_path` | 프로필 사진 파일 경로 `{path: ...}` | `LocalAvatarRepository` |
| `notifications` | — | `AppNotification` (현재 쓰는 곳 없음 → 항상 빈 목록) | `LocalNotificationRepository` |

`LocalStorageService.openBox`는 `Box<Map>`만 열기 때문에, 문자열 하나를 저장할 때도 `{value: ...}`처럼 Map으로 감싼다.

> 에뮬레이터에 새 빌드를 올릴 때 `flutter install`은 앱을 지웠다 다시 깔아서 Hive 데이터가 사라진다. `adb install -r`을 쓸 것.

### 5-2. 서버 (백엔드 `docs/API.md` 기준)

기본 주소: `http://10.0.2.2:8080/api/v1` (에뮬레이터 → PC의 localhost)

| 메서드 | 경로 | 호출하는 곳 | 화면에서 사용 중? |
|---|---|---|---|
| POST | `/auth/login` | `AuthRepository.login` | 로그인 |
| POST | `/auth/logout` | `AuthRepository.logout` | 내 정보, 사용자 설정 |
| POST | `/auth/signup` | `AuthRepository.signup` | ✗ (회원가입 화면 없음) |
| GET | `/users/me` | `UserRepository.getMe` | 로그인, 내 정보, 사용자 설정, 프로필 수정 |
| PATCH | `/users/me` | `UserRepository.updateMe` | 온보딩 1, 프로필 수정 |
| POST | `/children` | `ChildRepository.createChild` | 온보딩 2 |
| GET | `/children` | `ChildRepository.getChildren` | ✗ |

서버 에러는 전부 `ApiException(code, message)`로 바뀌어 나온다. 화면에서는 `on ApiException catch (e)` 후 `e.message`를 스낵바로 보여주면 된다(서버가 이미 한국어 문구를 준다).

**루틴·기기·템플릿은 아직 서버와 연결되지 않은 로컬 전용 데이터다.**

---

## 6. 화면 경로(라우트) 전체

`lib/app/router.dart` 한 파일에 모두 있다. 중첩(`routes: [...]`)으로 등록된 화면은 뒤로가기 시 부모 경로로 돌아간다.

| 경로 | 화면 클래스 | 파일 |
|---|---|---|
| `/splash` | `SplashScreen` | `splash/presentation/splash_screen.dart` |
| `/login` | `LoginScreen` | `auth/presentation/login_screen.dart` |
| `/login/social` | `LoginSocialScreen` (Figma 목업, 실사용 X) | `auth/presentation/login_social_screen.dart` |
| `/login/social/basic-info` | `LoginSocialBasicInfoScreen` | `auth/presentation/login_social_basic_info_screen.dart` |
| `/onboarding/guardian-info` | `GuardianInfoScreen` | `onboarding/presentation/guardian_info_screen.dart` |
| `/onboarding/child-info` | `ChildInfoScreen` | `onboarding/presentation/child_info_screen.dart` |
| `/onboarding/device-connection` | `DeviceConnectionScreen` | `onboarding/presentation/device_connection_screen.dart` |
| **`/`** (탭 0) | `HomeScreen` | `home/presentation/home_screen.dart` |
| **`/routine`** (탭 1) | `RoutineScreen` (달력) | `routine/presentation/routine_screen.dart` |
| `/routine/today` | `TodayRoutinesScreen` (전환 애니메이션 없음) | `routine/presentation/today_routines_screen.dart` |
| `/routine/detail/:id` | `RoutineDetailScreen` | `routine/presentation/routine_detail_screen.dart` |
| `/routine/edit/:id` | `RoutineEditScreen` | `routine/presentation/add_routine_screen.dart` ⚠ 같은 파일 |
| `/routine/add` | `RoutineTypeSelectScreen` | `routine/presentation/routine_type_select_screen.dart` |
| `/routine/add/single` | `AddRoutineScreen` (`extra`로 템플릿 전달 가능) | `routine/presentation/add_routine_screen.dart` |
| `/routine/add/compound` | `AddRoutineScreen(compound: true)` | 〃 |
| `/routine/add/templates` | `RoutineTemplateListScreen` | `routine/presentation/routine_template_list_screen.dart` |
| **`/devices`** (탭 2) | `DevicesScreen` | `devices/presentation/devices_screen.dart` |
| `/devices/add` | `AddDeviceScreen` | `devices/presentation/add_device_screen.dart` |
| `/devices/:name` | `DeviceDetailScreen` | `devices/presentation/device_detail_screen.dart` |
| `/devices/:name/wifi` | `WifiSettingsScreen` | `devices/presentation/wifi_settings_screen.dart` |
| `/devices/:name/settings` | `DeviceSettingsScreen` | `devices/presentation/device_settings_screen.dart` |
| `/devices/:name/stats` | `DeviceStatsScreen` | `devices/presentation/device_stats_screen.dart` |
| **`/profile`** (탭 3) | `ProfileScreen` | `profile/presentation/profile_screen.dart` |
| `/profile/edit` | `ProfileEditScreen` | `profile/presentation/profile_edit_screen.dart` |
| `/profile/language` | `LanguageScreen` | `profile/presentation/language_screen.dart` |
| `/profile/user-settings` | `UserSettingsScreen` | `profile/presentation/user_settings_screen.dart` |
| `/profile/login-history` | `LoginHistoryScreen` (예시 값) | `profile/presentation/login_history_screen.dart` |
| `/connected-devices` | `ConnectedDevicesScreen` (홈·기기 탭 공통) | `devices/presentation/connected_devices_screen.dart` |
| `/connected-devices/add` | `AddConnectedDeviceScreen` | `devices/presentation/add_connected_device_screen.dart` |
| `/watch-connection` | `WatchConnectionScreen` (어디서도 이동 안 함) | `watch_connection/presentation/watch_connection_screen.dart` |

`context.go(경로)` = 스택을 갈아치움(탭 이동, 로그인 후), `context.push(경로)` = 위에 쌓음(뒤로가기 가능), `context.pop()` = 뒤로.

---

## 7. 기능별 "무엇을 고치려면 어디를"

| 고치고 싶은 것 | 열 파일 |
|---|---|
| 하단 탭 모양/순서 | `app/widgets/bottom_nav_bar.dart` (`_routes` 배열) |
| 로그인 후 어디로 갈지 | `auth/presentation/login_screen.dart`의 `_submit` |
| 서버 주소 | `core/network/api_client.dart`의 `defaultApiBaseUrl` |
| 홈 화면 기기 카드·와이파이·현재 루틴 박스 | `home/presentation/widgets/device_overview.dart` (홈과 기기 상세가 공유) |
| 달력 표시, 날짜별 루틴 개수 배지 | `routine/presentation/routine_screen.dart` + `routineCountsByDayProvider` |
| 루틴 카드 한 장의 모양 | `routine/presentation/widgets/routine_card.dart` |
| 루틴 추가/수정 폼, 반복 설정 | `routine/presentation/add_routine_screen.dart` (1,164줄, 가장 큼) |
| 반복 규칙 → 날짜 목록 계산 | `routine/domain/routine_recurrence.dart` (순수 함수, 저장 시점에 날짜별 루틴을 여러 개 만든다) |
| 루틴 데이터 필드 추가 | `routine/domain/routine.dart`의 필드 + `toMap`/`fromMap` 둘 다 |
| 기기 목록 순서/색 배정 | `devices/data/device_providers.dart`, `deviceAccentFor` |
| 기기 통계(하루/주/월 성취도) | `devices/presentation/device_stats_screen.dart` |
| 내 정보 탭 설정 카드 | `profile/presentation/widgets/settings_card.dart` |
| 프로필 사진 고르기/저장 | `profile/data/avatar_providers.dart`의 `AvatarActions` |
| 앱 전체 글자 크기/버튼 크기 | `app/theme.dart` |

---

## 8. 자주 하는 작업 레시피

### 새 화면 추가
1. `features/<기능>/presentation/새_screen.dart` 생성. 데이터가 필요하면 `ConsumerWidget`.
2. 파일 맨 위 문서 주석에 **Figma 노드 id** 기록 (프로젝트 관례).
3. `app/router.dart`에 `GoRoute` 등록. 어느 탭에서 들어오는 하위 화면이면 그 탭의 `routes:` 안에 넣어야 뒤로가기가 자연스럽다.
4. 탭 화면이면 `Scaffold(bottomNavigationBar: BottomNavBar(currentIndex: n))`.
5. 상단 "‹ 제목"이 필요하면 `BackHeader` 재사용.

### 새 로컬 데이터 추가 (예: 메모)
1. `domain/memo.dart` — 필드 + `toMap`/`fromMap`.
2. `data/memo_repository.dart` — `abstract class MemoRepository` + `LocalMemoRepository`(박스 이름 상수 하나).
3. `data/memo_providers.dart` — `memoRepositoryProvider`, `memoListProvider`(FutureProvider), `MemoActions`(저장 후 `invalidate`).
4. 화면은 `ref.watch(memoListProvider)`로 읽고 `ref.read(memoActionsProvider).add(...)`로 쓴다.

### 로컬 데이터를 서버로 옮기기 (예: 루틴)
화면은 provider만 보고 있으므로 **화면 코드는 거의 안 건드린다.**
1. `ApiRoutineRepository implements RoutineRepository` 작성 (`children/data/child_repository.dart` 참고: `try { dio.get } on DioException catch (e) { throwAsApiException(e); }`).
2. `routineRepositoryProvider`가 `LocalRoutineRepository` 대신 새 클래스를 돌려주게 한 줄만 바꾼다.
3. `fromMap` 대신 서버 응답 모양에 맞는 `fromJson` 추가.

### 새 API 호출 추가
`apiClientProvider`(auth_providers.dart)를 `ref.watch`해서 저장소에 넘기면 인증 헤더는 자동이다.

---

## 9. 알아두면 좋은 주의점 / 정리 후보

| 항목 | 내용 | 제안 |
|---|---|---|
| `LocalStorageService` provider 중복 | routine(공개), auth·devices·profile·notifications(각자 private)에서 5번 따로 만든다. 상태가 없는 래퍼라 버그는 아니다. | `core/storage/`에 하나만 두고 모두 그걸 쓰게 정리 |
| `apiClientProvider` 위치 | `auth` 기능 안에 있어서 `children`이 `auth`를 import한다. | 서버 연동 기능이 늘면 `core/network/`로 이동 |
| 큰 파일 | `add_routine_screen.dart` 1,164줄(추가+수정 화면 같이 있음), `device_overview.dart` 653줄 | 반복 설정 탭, 할 일 목록 편집기 등을 `widgets/`로 분리 |
| 자동 로그인 없음 | 세션(accessUuid)이 저장돼 있어도 항상 `/login`을 거친다. 라우터에 `redirect`도 없다. | 스플래시에서 세션 확인 후 `/users/me` 호출로 분기 |
| 진입 경로 없는 화면 | `/watch-connection`으로 이동하는 코드가 없다. | BLE 스펙 나오면 연결하거나 삭제 |
| 데이터 연결 없는 화면 | 와이파이 설정, 기기 설정, 언어, 로그인 기록, 소셜 로그인, 기기 연결(온보딩 3)은 provider를 쓰지 않는 정적 화면 | 백엔드/BLE 스펙에 맞춰 순차 연결 |
| 미사용 패키지 | `flutter_tts`, `flutter_local_notifications` | 쓸 계획 없으면 `pubspec.yaml`에서 제거 |
| 미사용 API | `signup`, `getChildren` | 회원가입 화면·자녀 목록 화면 만들 때 사용 |
| 삭제 기능 없음 | 루틴/기기/템플릿 저장소에 `delete`가 없다. 수정은 같은 id로 `put`해서 덮어쓴다. | 필요해지면 저장소에 `delete` 추가 후 Actions에서 invalidate |
| 테스트 없음 | `test/` 폴더가 없다. | 순수 함수인 `routine_recurrence.dart`부터 단위 테스트 추가 추천 |
| CLAUDE.md 일부 오래됨 | "api_client에 base URL 없음", "onboarding 박스" 서술은 현재 코드와 다르다. | 다음 세션에 갱신 |

---

## 10. 명령어

```bash
flutter pub get        # 의존성 설치
flutter analyze        # 정적 분석
flutter run -d emulator-5554
flutter build apk
/home/sangmin/Android/Sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
