import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/routine.dart';
import 'routine_repository.dart';

final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return LocalRoutineRepository(ref.watch(localStorageServiceProvider));
});

final routineListProvider = FutureProvider<List<Routine>>((ref) {
  return ref.watch(routineRepositoryProvider).getRoutines();
});
