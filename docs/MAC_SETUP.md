# 맥북에서 이어서 작업하기 (세팅 가이드)

리눅스 데스크톱에서 하던 작업을 **맥북에서 그대로 이어받는** 방법. 기기 연동 미팅 준비물은
[DEVICE_INTEGRATION.md](DEVICE_INTEGRATION.md)에 있다.

## 0. 한눈에 보기 (순서대로)

1. 도구 설치: Homebrew → Flutter → Xcode(+시뮬레이터) → CocoaPods → (선택) Android Studio, Docker Desktop, Java 21
2. 코드 받기: `git clone` → `git switch feature` → `flutter pub get` → `cd ios && pod install`
3. 백엔드 받기·실행: 옆 폴더에 `2026-khu-artistic-software` clone → `./gradlew bootRun`
4. 앱 실행: 시뮬레이터/폰을 고르고 `flutter run -d <id>` (실기기면 `--dart-define=API_BASE_URL=…`)
5. 테스트 계정 만들기 (맥북의 DB는 **새로 시작**한다 — 아래 6장)

---

## 1. 도구 설치

```bash
# Homebrew (없다면)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter — 이 프로젝트는 Flutter 3.47.2 / Dart ^3.13.2 에서 확인했다
brew install --cask flutter           # 또는 https://docs.flutter.dev/get-started/install/macos
flutter --version                     # 3.47.x 면 OK. 크게 다르면 `flutter upgrade`/버전 맞추기

# iOS 빌드 도구
xcode-select --install                # Command Line Tools
#  → App Store에서 Xcode 설치 후 한 번 실행해 라이선스 동의
sudo xcodebuild -runFirstLaunch
brew install cocoapods

# 백엔드용 (맥북에서 백엔드를 직접 돌릴 때만)
brew install --cask docker            # Docker Desktop 실행해 두기
brew install openjdk@21               # Java 21 필요 (build.gradle 이 21 로 고정)
#  설치 후 안내대로 JAVA_HOME 을 잡는다. 예:
#  echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 21)' >> ~/.zshrc && source ~/.zshrc
```

그다음 **`flutter doctor`** 를 실행해서 `[✓]` 가 Flutter / Xcode / CocoaPods 에 떠야 한다.
(Android 쪽 `[✗]` 는 안드로이드를 안 쓰면 무시해도 된다.)

안드로이드도 쓸 거면 Android Studio를 설치하고 SDK·에뮬레이터를 만든다. `adb` 위치는 보통
`~/Library/Android/sdk/platform-tools/adb` 이다(PATH에 없을 수 있다).

## 2. 코드 받기

```bash
mkdir -p ~/Projects && cd ~/Projects
git clone https://github.com/Sang-min-le-e/pretty_sw.git
cd pretty_sw
git switch feature        # 최신 작업은 feature 브랜치(PR이 merge 전이어도 여기에 다 있다)
git pull
flutter pub get
cd ios && pod install && cd ..
```

- 이미 clone 해 둔 맥북이라면 `git switch feature && git pull` 만 하면 된다.
- 이 저장소의 **Git 규칙**(main 직접 push 금지, feature → PR → 직접 merge)은 [GIT_WORKFLOW.md](GIT_WORKFLOW.md).
  리눅스와 맥북이 **같은 `feature` 브랜치**를 쓰므로, 작업 시작 전 항상 `git pull`, 끝나면 push 해서 서로 어긋나지 않게 한다.

## 3. 백엔드 실행 (같은 맥북에서)

앱의 API 계약은 백엔드 저장소의 `docs/API.md` 가 기준이다.

```bash
cd ~/Projects
git clone https://github.com/najunho04/2026-khu-artistic-software.git 2026-khu-artistic-software   # 폴더 이름은 이대로(앱 문서가 이 이름을 가정)
cd 2026-khu-artistic-software
open -a Docker            # Docker Desktop 이 켜져 있어야 한다 (Postgres·Redis 를 자동으로 띄움)
./gradlew bootRun         # http://localhost:8080 에 뜬다 (첫 실행은 몇 분)
```

- DB(Postgres·Redis)는 `compose.yaml` 이 정의하고, Spring Boot 가 서버를 켤 때 **자동으로** 같이 띄운다.
- 확인: `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/v1/users/me` → **401** 이 나오면 정상(로그인 안 해서).
- 팀원 PC의 서버를 쓰는 경우 이 단계는 건너뛰고 4장의 `API_BASE_URL` 에 그 주소를 넣는다.

## 4. 앱 실행과 서버 주소

앱은 서버 주소를 **실행 환경에 맞춰 자동으로 고른다** (`lib/core/network/api_client.dart` 의 `resolveApiBaseUrl`).

| 어디서 실행 | 백엔드를 어디서 돌리나 | 주소 | 설정 |
|---|---|---|---|
| **iOS 시뮬레이터** | 같은 맥북 | `http://localhost:8080/api/v1` | 자동 (아무것도 안 해도 됨) |
| **안드로이드 에뮬레이터** | 같은 맥북 | `http://10.0.2.2:8080/api/v1` | 자동 |
| **실기기 폰(iPhone/안드로이드)** | 같은 맥북 | `http://<맥북 LAN IP>:8080/api/v1` | **`--dart-define` 필요** |
| 어느 쪽이든 | 다른 사람 PC / 배포 서버 | 그 서버 주소 | **`--dart-define` 필요** |

실기기에서 맥북의 서버를 쓰는 예:

```bash
ipconfig getifaddr en0                       # 맥북의 와이파이 IP, 예: 192.168.0.10
flutter devices                              # 연결된 폰/시뮬레이터 id 확인
flutter run -d <기기 id> --dart-define=API_BASE_URL=http://192.168.0.10:8080/api/v1
```

- **폰과 맥북이 같은 와이파이**여야 하고, 맥북 방화벽이 8080 을 막지 않아야 한다.
- iPhone 은 처음 접속할 때 **"로컬 네트워크" 권한 팝업**이 뜬다 → 허용해야 서버에 접속된다
  (`Info.plist` 의 `NSLocalNetworkUsageDescription`). 거절했다면 설정 → 앱 → 로컬 네트워크.
- 앱 안에서 주소를 바꾸는 기능은 없다. 주소를 바꾸려면 위처럼 다시 `flutter run`.

### iOS 실기기 / 서명 (처음 한 번)
```bash
open ios/Runner.xcworkspace            # ← .xcodeproj 가 아니라 .xcworkspace
```
Xcode 에서 **Runner → Signing & Capabilities → Team** 을 본인 Apple ID 로 선택한다. 번들 ID 는
`com.prettysw.routineApp`(iOS), 안드로이드는 `com.prettysw.routine_app` 이다. 팀을 못 고르면 번들 ID 를
본인만의 값(예: `com.<이름>.routineApp`)으로 **로컬에서만** 바꿔서 쓰고, 그 변경은 커밋하지 않는다.
폰에서는 설정 → 일반 → VPN 및 기기 관리 에서 개발자 앱을 "신뢰"해야 실행된다.

### 중요: 시뮬레이터에는 블루투스가 없다
- **iOS 시뮬레이터에서는 BLE(블루투스)가 동작하지 않는다.** 기기 연결 테스트는 **실기기**(iPhone 또는 안드로이드 폰)에서 해야 한다.
- 그 외 화면·서버 연동 확인은 시뮬레이터로 충분하다.

## 5. 자주 쓰는 명령

```bash
flutter pub get                 # pubspec.yaml 바꾼 뒤
flutter analyze                 # 커밋·PR 전에 반드시 (현재 "No issues found" 상태여야 함)
flutter run -d <id>             # 실행 (r = 핫 리로드, R = 핫 리스타트, q = 종료)
python3 docs/code-tour/build.py # 코드 투어 다시 만들기 (코드 줄이 바뀌면 필요)
python3 docs/code-tour/flow.py  # 파일 흐름 페이지 다시 만들기
```

- 안드로이드 에뮬레이터에 새 빌드를 올릴 때는 `flutter install` 대신 `adb install -r` (앱 데이터가 지워지지 않는다).
- 문제가 생기면: `flutter clean && flutter pub get && (cd ios && pod install)`.
- iOS 빌드가 이상하면: `cd ios && pod repo update && pod install`, Xcode 에서 Product → Clean Build Folder.

## 6. 맥북의 데이터는 새로 시작한다

- **백엔드 DB 는 컴퓨터마다 따로**다. 리눅스에서 만든 계정(`child-test@example.com` 등)은 맥북 DB 에 **없다**.
- 앱에는 **회원가입 화면이 아직 없다** → API 로 직접 계정을 만든다:

```bash
B=http://localhost:8080/api/v1; J='Content-Type: application/json'
U=$(curl -s -X POST $B/auth/signup -H "$J" -d '{"email":"me@example.com","password":"password123"}' \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessUuid'])")
curl -s -X PATCH $B/users/me -H "X-Access-Uuid: $U" -H "$J" -d '{"name":"테스터"}'        # 이름을 넣으면 온보딩을 건너뜀
curl -s -X POST  $B/children -H "X-Access-Uuid: $U" -H "$J" -d '{"name":"민준","birthDate":"2018-03-02","relationship":"PARENT"}'
```

  주의: **같은 계정으로 다시 로그인하면 이전 로그인이 무효화**된다(계정당 한 기기 한 세션). `signup` 으로 받은
  `accessUuid` 는 앱이 쓰던 세션이 아니니, 앱에서는 이메일·비밀번호로 로그인한다.
- 앱 안의 로컬 데이터(Hive: 기기 목록, 프로필 사진 경로, 로그인 세션)도 **폰/시뮬레이터마다 따로**다.

## 7. Claude Code 를 맥북에서 이어서 쓸 때

Claude Code 의 **메모리와 `CLAUDE.md` 는 컴퓨터마다 따로**다. `CLAUDE.md` 는 의도적으로 `.gitignore` 에 들어 있어서
`git pull` 로는 오지 않는다(되돌리지 말 것). 대신 아래가 저장소에 들어 있다:

| 파일 | 내용 |
|---|---|
| [HANDOFF.md](HANDOFF.md) | 최근 작업 상황, 다음 할 일 |
| [GIT_WORKFLOW.md](GIT_WORKFLOW.md) | "AI 에이전트가 지킬 규칙"(main 금지, PR만, 직접 merge 등) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 구조, 데이터 흐름, 서버 API 표 |
| [frontend_migration_plan.md](frontend_migration_plan.md) | 서버 연동 단계(1·2단계 완료, 3단계=기기) |
| [DEVICE_INTEGRATION.md](DEVICE_INTEGRATION.md) | 기기 연동 정리와 미팅 체크리스트 |

**가장 쉬운 방법**: 리눅스의 `CLAUDE.md` 를 맥북으로 복사한다(AirDrop/`scp`/메신저). 위치는 `pretty_sw/CLAUDE.md`.
복사하지 않았다면, 맥북의 Claude Code 에 **처음에 이렇게** 말하면 같은 규칙으로 이어서 작업한다:

```
이 저장소는 Flutter 앱(pretty_sw)이다. 먼저 docs/HANDOFF.md, docs/GIT_WORKFLOW.md,
docs/ARCHITECTURE.md, docs/DEVICE_INTEGRATION.md 를 읽어줘. 작업 규칙: main에 직접 커밋/푸시하지 않고
feature 브랜치에서 작업해 PR을 올린다(merge는 내가 한다). 코드 주석은 한국어로 충분히 단다.
커밋 전 flutter analyze 를 통과시키고, 줄이 바뀌면 docs/code-tour/build.py 도 돌려줘.
오늘은 docs/DEVICE_INTEGRATION.md 4장의 "앱 파트가 할 일"을 순서대로 진행하려고 해.
```

(리눅스에서 쌓인 Claude 개인 메모리 — 예: 에뮬레이터 설치 주의사항 — 는 위 문서들에 내용이 옮겨져 있어서 없어도 된다.)

## 8. 리눅스 쪽에 남은 것 (오늘 기준)

- 코드·문서는 **전부 push 됨**(`feature` 브랜치). PR #7(루틴 수정·삭제·템플릿)이 열려 있다 — 먼저 merge 해 두면 편하다.
- 리눅스 PC 의 로컬 백엔드 DB 에는 테스트 계정이 있다(`child-test@example.com` / `password123`, `device-test@example.com`).
  맥북 DB 에는 없다 → 6장대로 새로 만든다.
