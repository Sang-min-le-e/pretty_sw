import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/companion_character.dart';

class CharacterRepository {
  CharacterRepository(this._storage);

  static const _boxName = 'character';
  static const _key = 'companion';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  Future<CompanionCharacter> getCharacter() async {
    final box = await _box;
    final raw = box.get(_key);
    if (raw == null) return const CompanionCharacter();
    return CompanionCharacter.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> save(CompanionCharacter character) async {
    final box = await _box;
    await box.put(_key, character.toMap());
  }
}
