import 'package:hive_flutter/hive_flutter.dart';

/// 오프라인 우선 로컬 저장소. 박스 이름별로 Hive Box를 열어서 돌려준다.
class LocalStorageService {
  /// 이 앱이 쓰는 Hive 박스 이름 전부. 박스 이름은 각 기능의 저장소가 자기
  /// 파일에 따로 들고 있어서(`*_repository.dart`의 `_boxName`) 모아 둔 곳이
  /// 없다 — 탈퇴 때 전부 지워야 하므로 여기에 한 번 더 적는다. **새 박스를
  /// 만들면 이 목록에도 추가해야** 탈퇴 후에 데이터가 남지 않는다.
  static const allBoxNames = [
    'auth',
    'routines',
    'routine_templates',
    'devices',
    'profile',
    'notifications',
  ];

  Future<Box<Map>> openBox(String name) => Hive.openBox<Map>(name);

  /// [allBoxNames]의 박스를 열려 있든 아니든 디스크에서 지운다. 저장소들이
  /// 매번 `openBox`를 부르므로(열린 Box를 들고 있지 않음) 지운 뒤에 다시
  /// 읽으면 빈 박스가 새로 만들어진다.
  Future<void> deleteAllBoxes() async {
    for (final name in allBoxNames) {
      await Hive.deleteBoxFromDisk(name);
    }
  }
}
