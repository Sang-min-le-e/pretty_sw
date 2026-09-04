import 'package:hive_flutter/hive_flutter.dart';

/// 오프라인 우선 로컬 저장소. 박스 이름별로 Hive Box를 열어서 돌려준다.
class LocalStorageService {
  Future<Box<Map>> openBox(String name) => Hive.openBox<Map>(name);
}
