# 기기 연동 준비 (앱 · 기기 · 백엔드 3인 미팅용)

작성: 2026-10-06. 내일 앱·기기·백엔드 파트가 모여 **실제 기기를 연결**한다. 이 문서는 "무엇이 정해져야 하고,
누가 무엇을 해야 하는지"를 한 장에 모은 것이다. 서버 쪽 동작은 로컬 백엔드(`5cdde8d`)에 실제로 요청을 보내
확인했고, 앱 쪽은 아직 **연결 안 된 부분**을 그대로 적었다.

---

## 1. 전체 흐름 (백엔드 `docs/API.md` 14장 기준)

```
 앱(보호자 폰)                      서버                              기기(워치)
 ─────────────                      ────                              ──────────
 ① POST /api/v1/devices/pairing
    {childId, nickname}      ──▶  PENDING 행 생성
                             ◀──  {deviceId, pairingCode(숫자 10자리), expiresAt(10분)}
 ② [미정] 앱 ─────────────────────────────────────────────────────▶  와이파이 SSID/PW + pairingCode 전달
 ③                                                             기기가 집 와이파이에 접속
                                  ◀── POST /device-api/v1/claim
                                      {pairingCode, deviceUid, firmware}   (인증 헤더 없음)
                                  PENDING → ACTIVE, deviceAccessUuid 발급
                                  ──▶ {deviceId, deviceAccessUuid, serverTime}
                                                                   기기가 deviceAccessUuid를 영속 저장
 ④ GET /api/v1/devices/{deviceId} (폴링)
    status: PENDING → ACTIVE 이면 온보딩 완료
 ⑤                                ◀── POST /device-api/v1/sync   (X-Device-Uuid: deviceAccessUuid)
                                      {battery, firmware, completions[], dates[]}
                                  ──▶ {serverTime, accepted, routines[]}   (하루치 루틴)
```

- **앱 주소**는 `/api/v1/...`(헤더 `X-Access-Uuid`), **기기 주소**는 `/device-api/v1/...`(헤더 `X-Device-Uuid`)로 **경로가 다르다**.
  기기 쪽 코드가 `/api/v1/device-api/...`처럼 이어 붙이지 않게 주의(실수하기 쉽다).
- ②가 이 문서의 핵심 미정 사항이다(아래 3-A).

## 2. 서버가 실제로 동작하는지 확인한 결과 (2026-10-06, 로컬 백엔드)

기기 없이 `curl`만으로 ①③④⑤를 돌려 봤다. 문서대로 동작했다.

| 단계 | 결과 |
|---|---|
| ① 페어링 코드 발급 | `{"deviceId":2,"pairingCode":"2363475556","expiresAt":…,"status":"PENDING"}` |
| ④ claim 전 상태 조회 | `status: PENDING`, `battery/firmwareVersion/lastSyncedAt/pairedAt` 전부 `null` |
| ③ claim (헤더 없이) | `{"deviceId":2,"deviceAccessUuid":"bfb3042e-…","serverTime":"…"}` |
| ④ claim 후 상태 조회 | `status: ACTIVE`, `pairedAt` 채워짐 |
| ⑤ sync (루틴 받기) | 오늘 루틴과 할 일 목록이 내려옴, `accepted: 0` |
| ⑤ sync (완료 올리기) | `accepted: 1`. 앱의 달력 조회에서 해당 할 일이 `DONE`, `doneCount 1/2` |
| 기기 목록 | `battery: 79`, `firmwareVersion: "0.0.1"`, `lastSyncedAt` 채워짐 |
| 같은 코드로 다시 claim | `PAIRING_CODE_NOT_FOUND` 404 (이미 쓴 코드도 없는 코드와 같은 응답) |
| 잘못된 `X-Device-Uuid` | `DEVICE_UNAUTHORIZED` (기기는 재페어링을 안내해야 함) |

> **기기가 아직 없어도 앱을 테스트하는 방법**: 위 단계를 터미널에서 흉내 내면 된다. 아래 6장에 그대로 붙여 넣을 수 있는 스크립트가 있다.

## 3. 내일 정해야 하는 것

### 3-A. 앱 → 기기 전달 방식 (가장 중요, 아직 아무도 확정 안 함)

API 문서에는 "앱이 핫스팟으로 와이파이 SSID/PW + pairingCode를 전달(단방향)"이라고만 적혀 있다. 앱 코드는
`flutter_reactive_ble`로 **BLE 스캔까지만** 되어 있고(`lib/core/ble/ble_service.dart`), GATT UUID가 없다.
**기기 파트와 정해야 할 것**:

1. **전송 수단**: BLE GATT? 기기가 켜는 임시 와이파이(AP)에 폰이 접속? 폰 핫스팟에 기기가 접속?
   - iOS는 임의의 와이파이에 앱이 마음대로 접속하기 어렵다(별도 권한/제약). BLE가 가장 현실적이다(제안).
2. **BLE라면**: 서비스 UUID, 쓰기용 특성 UUID(필요하면 상태 알림용 특성), 광고 이름 규칙(스캔에서 우리 기기만 골라내려고).
3. **전달 내용과 형식**: `ssid`, `password`, `pairingCode`(10자리 숫자 문자열, 앞자리 0 유지). JSON? 구분자 문자열? 글자 인코딩(UTF-8)? 한 번에 보낼 크기(MTU 때문에 나눠 보내야 할 수 있음)?
4. **기기의 응답**: 받았다는 확인(ack)을 BLE로 돌려주나? 문서는 "단방향, 기기는 응답만"이라고 했다. 와이파이 접속 실패를 앱이 알 방법이 있나(없으면 폴링 타임아웃만으로 알게 됨).
5. **와이파이 비밀번호 보호**: BLE로 평문 전송해도 되는지(최소한 페어링/본딩 사용 여부).

### 3-B. 서버 주소를 기기가 아는 방법
- 기기는 **어디로** `claim`/`sync`를 보내나? 서버 주소를 **기기 펌웨어에 박을지**, **앱이 3-A에서 함께 전달할지** 정해야 한다.
- 내일 테스트용 백엔드를 **누구의 PC에서** 돌리나? 기기와 폰이 **같은 와이파이**에서 그 PC의 LAN 주소(예: `192.168.0.10:8080`)에 접속할 수 있어야 한다(방화벽·게스트 와이파이 격리 주의). 아니면 배포 서버가 있나?
- HTTP(비TLS)로 테스트해도 되는지(기기 쪽 HTTPS 지원 여부).

### 3-C. 서버(백엔드) 파트와 확인할 것
| 항목 | 현재 | 확인/결정 |
|---|---|---|
| 폴링 주기(15장 #5) | 미확정. **타임아웃은 10분 확정** | 앱은 **2초 간격, 최대 10분**을 제안. 괜찮은지 |
| `sync`의 `dates` 최대 길이(#8) | 상한 제안 3일 | 기기가 며칠치를 받을지(오늘~내일?) |
| `sync` 부분 실패 | 이미 삭제된 `smallRoutineId` 처리 미확정 | 서버는 **무시하고 진행**을 권장. 확정 필요 |
| `deviceUid` | 기기가 만든 고유 문자열(중복 시 `DEVICE_UID_ALREADY_PAIRED` 409) | 형식(MAC 주소? 시리얼?) |
| `firmware` | 문자열 | 형식 |
| 페어링 만료 | 10분. 만료 시 `PAIRING_CODE_EXPIRED` 410 | 앱이 "다시 시도" 화면을 어떻게 보일지 합의 |
| 재페어링 | 같은 기기를 다른 자녀에게/다시 | `deviceAccessUuid`를 잃어버리면 재페어링뿐 — 기기가 **지워지지 않는 저장소**에 저장해야 함 |

### 3-D. 기기 파트가 해야 하는 일 (체크리스트)
- [ ] 앱이 보낸 와이파이 정보로 집 와이파이 접속
- [ ] `POST /device-api/v1/claim` (`pairingCode`, `deviceUid`, `firmware`) → `deviceAccessUuid` 수신, **비휘발 저장**
- [ ] `serverTime`으로 RTC 보정
- [ ] 주기적으로 `POST /device-api/v1/sync` (`X-Device-Uuid` 헤더, `battery`, `firmware`, `completions: []`(없으면 빈 배열, null 금지), `dates`)
- [ ] 할 일 완료 시 `completions`에 `{smallRoutineId, status: "DONE", completedAt}` (`status`는 `DONE`/`PENDING` 두 값만. 오타면 요청 전체가 400)
- [ ] `DEVICE_UNAUTHORIZED` 수신 시 재페어링 안내
- [ ] 같은 `completions`를 재전송해도 안전함(멱등) — 네트워크 실패 시 재시도 가능

## 4. 앱 파트가 할 일 (내가 만들 것)

현재 앱은 기기 기능이 **전부 로컬 가짜**다(Hive 저장, 몇 초 기다리는 척). 서버 연동 작업(마이그레이션 3단계):

1. **권한 (이미 추가함)**: Android `BLUETOOTH_SCAN/CONNECT` 등, iOS `NSBluetoothAlwaysUsageDescription`·`NSLocalNetworkUsageDescription`. **런타임 권한 요청 코드**(예: `permission_handler`)는 아직 없다 → 3-A 확정 후.
2. **BLE 서비스**: `core/ble/ble_service.dart`에 서비스/특성 UUID와 "SSID/PW/코드 쓰기" 구현 (3-A 확정 후).
3. **페어링 시작**: `POST /devices/pairing` (`childId` = 현재 자녀, `nickname`). 응답의 `deviceId`·`pairingCode` 보관.
4. **기기 연결 화면**: 온보딩 3단계(`device_connection_screen.dart`)와 기기 탭 "기기 추가하기"(`add_device_screen.dart`)의 가짜 대기를 걷어내고 ② 전달 → ④ 폴링(`GET /devices/:id`, 2초, 최대 10분) → `ACTIVE`면 완료. 실패·만료 시 재시도 화면.
5. **기기 목록**을 서버로: `GET /children/:childId/devices`(닉네임, `status`, `battery`, `firmwareVersion`, `lastSyncedAt`, `pairedAt`). PENDING 기기는 `battery` 등이 `null`이니 **반드시 null 처리**.
6. **기기 관리**: 이름 변경 `PATCH /devices/:id`, 연결 해제 `DELETE /devices/:id`.
7. **로컬 기기 코드 정리**: `features/devices/data/`(Hive)를 `Api*Repository`로 교체(루틴·템플릿과 같은 방식), `deviceListProvider`·`DeviceActions` 갱신.
8. **미정 설계**: 홈 캐러셀·기기 탭이 지금 "기기 = 이름 하나"인데, 서버는 **자녀당 여러 기기**다. 화면을 자녀 기준으로 볼지 기기 기준으로 볼지 정해야 한다(현재 선택된 자녀의 기기 목록을 보여주는 쪽을 제안).

> 이미 끝난 것: 로그인/자녀/루틴/템플릿 서버 연동, 현재 자녀 선택 칩. 완료 표시(`DONE`)는 기기가 `sync`로 올리면 앱의 루틴 카드·상세 진행 링에 바로 반영된다(위 2장에서 확인).

## 5. 내일 테스트 시나리오 (순서대로)

1. 백엔드 실행 + 앱이 그 서버에 접속되는지(로그인 성공) 확인 — 폰이면 `--dart-define=API_BASE_URL=…` ([MAC_SETUP.md](MAC_SETUP.md))
2. 앱: 자녀 선택 → "기기 추가하기" → 페어링 코드 발급 확인(서버 응답 `PENDING`)
3. 앱 → 기기로 SSID/PW/코드 전달(3-A) → 기기가 와이파이 접속
4. 기기 → 서버 `claim` 성공 → 앱 폴링이 `ACTIVE`로 바뀌며 완료 화면
5. 앱에서 루틴 하나 만들기 → 기기 `sync`로 내려받아 화면에 표시
6. 기기에서 할 일 완료 → `sync`로 올림 → 앱에서 카드 배지·상세 진행 링이 바뀌는지
7. 실패 경로: 코드 만료(10분), 잘못된 와이파이 비밀번호, 이미 쓴 코드 재사용, `deviceAccessUuid` 삭제 후 `DEVICE_UNAUTHORIZED` 복구(재페어링)

## 6. 기기 없이 서버만으로 흐름 확인하기 (그대로 실행 가능)

기기가 늦어져도 앱의 폴링·완료 표시는 이 스크립트로 확인할 수 있다. **로컬 백엔드가 `localhost:8080`에 떠 있어야 한다.**
기기 흉내는 맨 아래 두 줄이다. 앱이 보는 계정으로 시험하려면 `U`를 그 계정의 `accessUuid`로 바꾼다
(⚠ 같은 계정으로 다시 로그인하면 앱의 세션이 무효화되니 주의 — 로그인은 한 계정당 한 곳만 유지된다).

```bash
H=http://localhost:8080; B=$H/api/v1; D=$H/device-api/v1; J='Content-Type: application/json'

# (앱 역할) 가입 → 이름 → 자녀 → 페어링 코드
U=$(curl -s -X POST $B/auth/signup -H "$J" -d '{"email":"dev-sim@example.com","password":"password123"}' \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessUuid'])")
curl -s -X PATCH $B/users/me -H "X-Access-Uuid: $U" -H "$J" -d '{"name":"테스터"}' >/dev/null
C=$(curl -s -X POST $B/children -H "X-Access-Uuid: $U" -H "$J" \
    -d '{"name":"민준","birthDate":"2018-03-02","relationship":"PARENT"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['childId'])")
P=$(curl -s -X POST $B/devices/pairing -H "X-Access-Uuid: $U" -H "$J" -d "{\"childId\":$C,\"nickname\":\"테스트 시계\"}")
echo "$P"
CODE=$(echo "$P" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['pairingCode'])")
DID=$(echo "$P" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['deviceId'])")

# (기기 역할) claim → deviceAccessUuid
DU=$(curl -s -X POST $D/claim -H "$J" -d "{\"pairingCode\":\"$CODE\",\"deviceUid\":\"SIM-0001\",\"firmware\":\"0.0.1\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['deviceAccessUuid'])")

# (앱 역할) 폴링으로 ACTIVE 확인
curl -s $B/devices/$DID -H "X-Access-Uuid: $U"

# (기기 역할) sync: 루틴 받기 / 완료 올리기
TODAY=$(date +%F)
curl -s -X POST $D/sync -H "X-Device-Uuid: $DU" -H "$J" \
  -d "{\"battery\":80,\"firmware\":\"0.0.1\",\"completions\":[],\"dates\":[\"$TODAY\"]}"
# 완료 올리기: smallRoutineId는 위 응답에서 가져온다
#   -d '{"battery":79,"firmware":"0.0.1","completions":[{"smallRoutineId":<id>,"status":"DONE","completedAt":"<UTC ISO>"}],"dates":["<날짜>"]}'
```

## 7. 준비물 체크리스트
- [ ] 백엔드를 돌릴 PC 1대(같은 와이파이, 방화벽에서 8080 허용) 또는 배포 서버 주소
- [ ] 실기기 폰 (iOS 시뮬레이터는 **BLE가 없다** — BLE 테스트는 실기기 iPhone 또는 안드로이드 폰 필수)
- [ ] 기기(워치) + 집 와이파이 정보(2.4GHz 여부 확인 — 임베디드 와이파이 모듈은 흔히 2.4GHz만 지원)
- [ ] 테스트 계정 1개와 자녀 1명(위 스크립트 또는 앱 가입 화면은 아직 없음 → `signup` API로 생성)
- [ ] 앱 PC(맥북) 세팅: [MAC_SETUP.md](MAC_SETUP.md)
