# 이어받기 노트 (2026-10-05 세션 → 맥북)

리눅스 데스크톱에서 한 작업을 맥북에서 이어서 보기 위한 정리. 최신 상태는 항상 `feature` 브랜치에 있다.

## 1. 맥북에서 시작하기

```bash
git clone https://github.com/Sang-min-le-e/pretty_sw.git   # 이미 있으면 생략
cd pretty_sw
git fetch origin
git switch feature
git pull
flutter pub get
```

브라우저로 바로 열어볼 파일 (`open` 명령은 macOS 기본 브라우저로 연다):
```bash
open docs/code-tour/tour.html   # 코드 한 줄씩 따라 읽기 (1장: 앱 시작 → 로그인)
open docs/code-map.html         # 프로젝트 구조 한 장 요약
```
같은 내용을 claude.ai에 로그인한 상태에서 링크로도 볼 수 있다(아래 4장).

**맥에서 앱/서버를 실행할 때 다른 점**
- Flutter, Android Studio(에뮬레이터)를 맥에 따로 설치해야 한다. `flutter doctor`로 확인.
- 서버 주소가 `http://10.0.2.2:8080/api/v1`로 고정돼 있다(`lib/core/network/api_client.dart`). **안드로이드 에뮬레이터에서는 맥에서도 그대로 동작**하지만, iOS 시뮬레이터는 `10.0.2.2`를 모른다(`localhost`를 써야 함). 지금은 안드로이드 에뮬레이터로 실행하는 것을 권장.
- 백엔드(`2026-khu-artistic-software`)를 맥에서 띄우려면 Docker Desktop과 Java 21이 필요하다. 그 다음 백엔드 폴더에서 `./gradlew bootRun`을 실행한다.
- `CLAUDE.md`의 `adb` 경로(`/home/sangmin/Android/...`)는 리눅스 데스크톱 기준이다. 맥에서는 보통 `~/Library/Android/sdk/platform-tools/adb`.
- **Claude Code 설정은 맥으로 넘어가지 않는다.** 메모리는 컴퓨터마다 따로 저장되고, `CLAUDE.md`는 `.gitignore`에 들어 있다(로컬 전용, 커밋 `90c8eff`). 맥에서 Claude Code를 쓸 때 할 수 있는 방법은 두 가지다.
  - 데스크톱의 `CLAUDE.md`를 맥의 같은 위치로 복사한다(에어드롭, 메일 등). 리눅스에서 오늘 최신 내용으로 갱신해 뒀다.
  - 또는 첫 메시지로 "`docs/HANDOFF.md`와 `docs/GIT_WORKFLOW.md`를 먼저 읽어줘"라고 한다. 에이전트가 지킬 규칙은 `GIT_WORKFLOW.md` 마지막 장에 적어 뒀다.

## 2. 오늘(10/5) 한 일

| 무엇 | 결과물 |
|---|---|
| 프론트엔드 전체 구조 분석 | `docs/ARCHITECTURE.md` (글), `docs/code-map.html` (그림) |
| 코드 따라 읽기 가이드 1장 | `docs/code-tour/` — main.dart → 로그인 완료까지 14개 파일, 한 줄씩 해설 |
| 서버 연결 상태 점검 | 로그인·내 정보·자녀 등록만 서버, 루틴·기기·템플릿·프로필 사진은 Hive(로컬) |
| 백엔드 pull 내용 정리 | 아래 3장 |
| 작업 방식 결정 | KHU AI Developer Blueprint 방식 + `feature` 브랜치 → PR → 본인이 merge (`docs/GIT_WORKFLOW.md`) |
| GitHub 설정 | `main` 보호: PR 필수, 승인 0명, 관리자 우회 금지 |
| 코드 변경 (본인) | 앱 이름 `TOMO`(main `8255501`), 버튼 `minimumSize: Size.zero`(feature `dcc641c`) |

## 3. 백엔드에서 바뀐 것 (pull: `229a924` → `5cdde8d`)

- **회원 탈퇴 `DELETE /users/me` 구현됨.** 자녀, 기기, 루틴, 템플릿까지 같이 soft delete한다. → 앱의 "탈퇴하기"는 아직 로그아웃만 하므로 **연결할 차례**.
- **캐릭터 API 2개 구현됨.** 다만 도감 데이터가 비어 있어서 항상 빈 목록이 온다. → 화면은 아직 만들 필요 없음.
- **버그 수정 다수.** 400/500 구분, 루틴 할 일 순서, 동시 요청 처리, 생년월일 KST 판정.
- **응답 변경.** 자녀 응답에서 `createdAt`이 빠졌다(앱 영향 없음). `GET /devices/:id` 응답에 `childId`가 추가됐다.

## 4. 링크 (claude.ai 로그인 필요, 비공개)

- 코드 따라 읽기: https://claude.ai/artifact/XnouS3dEfxWZrHyCWUkEd7
- 코드 지도: https://claude.ai/artifact/3j9LETKnaNvSepuYJZPr4i
- 빌드 노트(세션 기록): https://claude.ai/code/artifact/133d6133-864f-4e1e-ab96-ef79d60f26b5

## 5. 다음 할 일 (추천 순서)

1. **이 `feature` 브랜치를 PR로 올려 merge하기.** 버튼 크기 수정과 이 문서들이 들어 있다. GIT_WORKFLOW의 흐름을 처음 연습하기에 좋다.
2. **코드 따라 읽기 1장 읽기.** 막히는 줄은 "login_screen 46줄"처럼 파일과 줄 번호로 질문한다.
3. **테스트 + CI 추가.** `test/routine_recurrence_test.dart`(순수 함수라 쉬움)와 `.github/workflows/ci.yml`(PR마다 `flutter analyze` + `flutter test`).
4. **탈퇴 버튼을 `DELETE /users/me`에 연결.** `profile_screen.dart`, `user_settings_screen.dart`.
5. **코드 따라 읽기 2장(홈/기기), 3장(루틴)** 만들기.

## 6. 알아둘 것

- 커밋 `8255501`의 메시지는 "minimumSize 제거"인데, 실제 변경은 앱 이름 변경, theme 주석 삭제, ARCHITECTURE.md 추가다. 버튼 수정은 그 뒤 `dcc641c`(feature)에서 들어갔다.
- `minimumSize: Size.zero`로 바꿔서 이제 앱 전체 기본 버튼 최소 크기(원래 88×56) 제한이 없다. 큰 터치 영역이 필요한 화면은 버튼마다 크기를 지정해야 한다.
- `pubspec.yaml`의 `flutter_tts`, `flutter_local_notifications`는 아직 아무 데서도 쓰지 않는다.
