import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/routine_template.dart';

abstract class RoutineTemplateRepository {
  Future<List<RoutineTemplate>> getTemplates();
  Future<void> saveTemplate(RoutineTemplate template);
}

/// Hive 기반 로컬 구현체. [routine_repository.dart]의 [LocalRoutineRepository]와
/// 같은 패턴 — 박스 이름만 다르다.
class LocalRoutineTemplateRepository implements RoutineTemplateRepository {
  LocalRoutineTemplateRepository(this._storage);

  static const _boxName = 'routine_templates';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<List<RoutineTemplate>> getTemplates() async {
    final box = await _box;
    return box.values
        .map((raw) => RoutineTemplate.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<void> saveTemplate(RoutineTemplate template) async {
    final box = await _box;
    await box.put(template.id, template.toMap());
  }
}
