/// 서버가 알고 있는 자녀 기기 하나(`docs/API.md` 7장 `GET /children/:childId/devices`).
///
/// 홈 화면의 "연결된 기기" 카드와 "연결된 기기" 화면이 보여주는 목록의 원소다.
class ConnectedDevice {
  const ConnectedDevice({
    required this.deviceId,
    required this.name,
    required this.status,
    this.battery,
    this.firmwareVersion,
    this.lastSyncedAt,
    this.pairedAt,
  });

  final int deviceId;

  /// 서버의 `nickname`. 화면마다 접미사를 다르게 붙여서 보여준다 — 홈/상세
  /// 화면 제목은 "지예의 기기", 목록 한 줄은 "지예님의 기기"처럼.
  final String name;

  /// `PENDING`(페어링 코드만 발급, 기기가 아직 claim 안 함) 또는 `ACTIVE`.
  final String status;

  /// `PENDING`이면 아래 값들은 전부 `null`이다.
  final int? battery;
  final String? firmwareVersion;
  final DateTime? lastSyncedAt;
  final DateTime? pairedAt;

  bool get isActive => status == 'ACTIVE';

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return ConnectedDevice(
      deviceId: (json['deviceId'] as num).toInt(),
      name: json['nickname'] as String? ?? '',
      status: json['status'] as String,
      battery: (json['battery'] as num?)?.toInt(),
      firmwareVersion: json['firmwareVersion'] as String?,
      lastSyncedAt: time('lastSyncedAt'),
      pairedAt: time('pairedAt'),
    );
  }
}

/// 서버가 준 배터리·마지막 동기화 시각으로 홈/상세 화면의 "기기 상태"를 그린다.
extension ConnectedDeviceStatus on ConnectedDevice {
  /// 기기가 `sync`를 올리는 주기가 아직 확정되지 않아서(`docs/DEVICE_INTEGRATION.md`
  /// "정하지 못한 것"), 마지막 동기화가 이 안이면 온라인으로 본다. 주기가 정해지면 조정.
  static const onlineWindow = Duration(minutes: 10);

  bool get isOnline =>
      lastSyncedAt != null && DateTime.now().difference(lastSyncedAt!) <= onlineWindow;

  /// 배터리를 아직 못 받았으면(`null`) `--%`.
  String get batteryLabel => battery == null ? '--%' : '$battery%';

  /// "방금 동기화됨" / "3분전 동기화됨" / "동기화 기록 없음".
  String get syncLabel {
    final at = lastSyncedAt;
    if (at == null) return '동기화 기록 없음';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '방금 동기화됨';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분전 동기화됨';
    if (diff.inHours < 24) return '${diff.inHours}시간전 동기화됨';
    return '${diff.inDays}일전 동기화됨';
  }
}

/// `POST /devices/pairing` 응답. 앱은 [pairingCode]를 BLE로 기기에 넘기고,
/// [deviceId]로 `ACTIVE`가 될 때까지 폴링한다.
class PairingTicket {
  const PairingTicket({
    required this.deviceId,
    required this.pairingCode,
    required this.expiresAt,
  });

  final int deviceId;

  /// 숫자 10자리 **문자열**(앞자리 0 유지).
  final String pairingCode;
  final DateTime expiresAt;

  factory PairingTicket.fromJson(Map<String, dynamic> json) {
    return PairingTicket(
      deviceId: (json['deviceId'] as num).toInt(),
      pairingCode: json['pairingCode'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
