import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/routine.dart';

abstract class RoutineRepository {
  /// 저장된 모든 루틴을 날짜 상관없이 통째로 돌려준다. 특정 날짜만 걸러내는
  /// 작업은 [routine_providers.dart]의 파생 provider들이 담당한다 —
  /// 루틴 개수가 많지 않은 로컬 앱이라 매번 전체를 불러온 뒤 메모리에서
  /// 걸러도 충분하기 때문이다.
  Future<List<Routine>> getRoutines();
  Future<void> saveRoutine(Routine routine);
}

/// Hive 기반 로컬 구현체. 백엔드 동기화가 붙기 전까지는 이걸로 오프라인 CRUD를 처리한다.
class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository(this._storage);

  static const _boxName = 'routines';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<List<Routine>> getRoutines() async {
    final box = await _box;
    return box.values
        .map((raw) => Routine.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<void> saveRoutine(Routine routine) async {
    final box = await _box;
    await box.put(routine.id, routine.toMap());
  }
}
