import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';

/// 프로필 사진 파일 경로를 저장/조회하는 저장소. 백엔드에 아바타 업로드
/// API가 없어서(`docs/API.md`엔 프로필 이미지 필드가 없다) 이미지 자체를
/// 서버로 올리지 않고, 기기 안에 복사해둔 파일의 경로만 Hive에 남긴다 —
/// devices/routine 기능과 같은 "로컬 우선" 패턴이다.
abstract class AvatarRepository {
  Future<String?> getAvatarPath();
  Future<void> setAvatarPath(String path);
}

class LocalAvatarRepository implements AvatarRepository {
  LocalAvatarRepository(this._storage);

  static const _boxName = 'profile';
  static const _avatarPathKey = 'avatar_path';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<String?> getAvatarPath() async {
    final box = await _box;
    // Hive Box<Map>은 값 하나에 Map을 저장하는 구조라, 문자열 하나만
    // 넣더라도 {'path': ...} 형태로 감싼다(devices/routine 박스들과
    // 같은 Box<Map> 타입을 쓰려고 LocalStorageService.openBox가
    // Box<Map>만 열어주기 때문).
    final raw = box.get(_avatarPathKey);
    return raw == null ? null : raw['path'] as String?;
  }

  @override
  Future<void> setAvatarPath(String path) async {
    final box = await _box;
    await box.put(_avatarPathKey, {'path': path});
  }
}
