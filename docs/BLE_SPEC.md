# 앱 ↔ 워치 BLE 스펙 (기기 파트 전달용)

앱이 기기에 **집 와이파이 정보 + 페어링 코드 + 서버 주소**를 BLE로 넘기는 방법이다. 값의 기준은
`lib/core/ble/watch_gatt.dart`. 기기 펌웨어는 이 문서를 따라 구현한다(바꾸고 싶으면 앱과 같이 바꾼다).

## 1. 역할

- 기기 = **GATT 서버(Peripheral)**, 앱 = Central. 기기는 켜지면(페어링 모드) 광고한다.
- 앱 → 기기 **한 방향 쓰기**가 필수이고, 기기 → 앱 상태 알림(notify)은 선택이다.

## 2. 광고

- 광고 패킷에 아래 **서비스 UUID**를 넣는다. 앱은 이 UUID로 스캔해서 우리 기기만 찾는다.
- 광고 이름(Local Name)은 자유(앱에 표시용, 예: `Watch-1A2B`).

## 3. GATT

| 이름 | UUID | 속성 | 방향 |
|---|---|---|---|
| 서비스 | `7f3a0001-5d2e-4c1b-9a6f-8e4b2c1d0a00` | | |
| wifiConfig | `7f3a0002-5d2e-4c1b-9a6f-8e4b2c1d0a00` | **Write** (with response) | 앱 → 기기 |
| status | `7f3a0003-5d2e-4c1b-9a6f-8e4b2c1d0a00` | **Notify** (선택) | 기기 → 앱 |

## 4. wifiConfig 에 쓰는 내용

**UTF-8 JSON 한 줄 + 끝 표시 `\n`(0x0A)**. 길어서 여러 번 나눠 쓴다.

```json
{"ssid":"우리집 WiFi","password":"pw 1234","pairingCode":"0012345678","serverUrl":"http://192.168.0.10:8080"}
```

| 키 | 설명 |
|---|---|
| `ssid` | 와이파이 이름. 한글·공백 가능(UTF-8) |
| `password` | 와이파이 비밀번호. 열린 네트워크면 빈 문자열 |
| `pairingCode` | 서버가 발급한 **숫자 10자리 문자열**. 앞자리 0이 있을 수 있어 **문자열로 처리** |
| `serverUrl` | 기기가 `claim`/`sync` 를 보낼 서버 주소(경로 없음). 뒤에 `/device-api/v1/...` 를 붙여 사용 |

- **조각 쓰기**: 한 번에 최대 **20바이트**씩 순서대로 쓴다(MTU 협상 없이도 되는 값). 기기는 받은 바이트를
  **`\n` 이 올 때까지 이어 붙인 뒤** 파싱한다. `\n` 은 JSON 값 안에 나오지 않는다(JSON이 이스케이프함).
- 기기는 한 번 받은 뒤 JSON을 파싱하고, 새 쓰기가 시작되면 이전 버퍼를 버린다.

## 5. status (선택) 알림 값 — UTF-8 문자열

| 값 | 의미 |
|---|---|
| `RECEIVED` | 전체를 받아서 파싱 성공 |
| `WIFI_OK` | 와이파이 접속 성공 |
| `WIFI_FAIL` | 와이파이 접속 실패(앱이 오류로 표시) |
| `PARSE_ERROR` | JSON/형식 오류(앱이 오류로 표시) |

상태를 안 보내도 된다. 앱은 **쓰기가 끝난 뒤 3초만** 상태를 기다리고, 실제 완료는 서버 폴링으로 판단한다.

## 6. 이후 기기 동작 (서버 API)

1. 위 정보로 와이파이 접속
2. `POST {serverUrl}/device-api/v1/claim` — `{"pairingCode":"…","deviceUid":"…","firmware":"…"}`
   → 응답의 `deviceAccessUuid` 를 **비휘발 저장**
3. 이후 `POST {serverUrl}/device-api/v1/sync` (헤더 `X-Device-Uuid`)

자세한 요청/응답은 [DEVICE_INTEGRATION.md](DEVICE_INTEGRATION.md) 1·3-D장.

## 7. 정하지 못한 것 (기기 파트와 확인)

- 페어링 코드는 **10분 후 만료**. 기기가 그 안에 와이파이 접속과 `claim` 을 끝내야 한다.
- 비밀번호가 BLE로 평문 전송된다. 본딩/암호화 사용 여부는 아직 안 정했다.
- iOS는 연결 시 MTU를 자동 협상한다. 20바이트 조각은 어느 쪽에서도 안전하지만 느리다 → 필요하면 늘린다.
