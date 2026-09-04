import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/big_routine.dart';

/// 루틴 데이터를 어디서/어떻게 가져오는지는 이 인터페이스 뒤에 숨긴다.
///
/// 왜 인터페이스를 따로 두나? 지금은 Hive(로컬)만 쓰지만, 백엔드 파트 API가 준비되면
/// "로컬에 저장 + 서버로도 동기화"하는 구현체를 하나 더 만들어서 갈아끼울 수 있게
/// 하기 위해서다. 화면(presentation) 쪽 코드는 RoutineRepository 타입만 알면 되고,
/// 실제 구현이 Hive인지 서버 연동인지는 몰라도 된다 (의존성 역전 원칙).
abstract class RoutineRepository {
  /// 저장된 모든 빅루틴을 가져온다.
  Future<List<BigRoutine>> getAllBigRoutines();

  /// 캘린더에서 특정 날짜를 눌렀을 때, 그 날짜에 적용되는 빅루틴만 필터링해서 가져온다.
  Future<List<BigRoutine>> getBigRoutinesForDate(DateTime date);

  /// 새로 만들거나(id가 새 것) 기존 걸 수정할 때(같은 id) 모두 이 메서드 하나로 처리한다.
  /// Hive의 `box.put(key, value)`가 원래 "있으면 덮어쓰고 없으면 새로 만드는" 동작이라
  /// upsert(update or insert)를 자연스럽게 표현할 수 있다.
  Future<void> saveBigRoutine(BigRoutine routine);

  Future<void> deleteBigRoutine(String id);
}

/// Hive 기반 로컬 구현체.
///
/// Hive는 "박스(Box)"라는 이름의 key-value 저장소 단위를 쓴다. 여기서는
/// 'big_routines'라는 이름의 박스 하나에 빅루틴 id를 key로, 빅루틴을 Map으로
/// 바꾼 값을 value로 저장한다. 스몰루틴은 별도 박스 없이 BigRoutine의 Map 안에
/// 리스트로 함께 저장된다 — 빅루틴 없이는 스몰루틴이 존재할 이유가 없는
/// "생명주기가 같은" 하위 개념이기 때문이다(도메인 주도 설계에서 말하는 애그리거트).
class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository(this._storage);

  static const _boxName = 'big_routines';
  final LocalStorageService _storage;

  Future<Box<Map>> get _box => _storage.openBox(_boxName);

  @override
  Future<List<BigRoutine>> getAllBigRoutines() async {
    final box = await _box;
    return box.values
        .map((raw) => BigRoutine.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<List<BigRoutine>> getBigRoutinesForDate(DateTime date) async {
    final all = await getAllBigRoutines();
    return all.where((routine) => routine.appliesOn(date)).toList()
      // 화면에 보여줄 때 시작 시간 순서로 정렬해두면 사용자가 하루 흐름을 읽기 쉽다.
      ..sort(
        (a, b) => (a.startTime.hour * 60 + a.startTime.minute).compareTo(
          b.startTime.hour * 60 + b.startTime.minute,
        ),
      );
  }

  @override
  Future<void> saveBigRoutine(BigRoutine routine) async {
    final box = await _box;
    await box.put(routine.id, routine.toMap());
  }

  @override
  Future<void> deleteBigRoutine(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
