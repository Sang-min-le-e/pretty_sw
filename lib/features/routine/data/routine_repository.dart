import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/routine.dart';

abstract class RoutineRepository {
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
