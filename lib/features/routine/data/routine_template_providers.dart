import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/routine_template.dart';
import 'routine_providers.dart';
import 'routine_template_repository.dart';

final routineTemplateRepositoryProvider = Provider<RoutineTemplateRepository>((ref) {
  return LocalRoutineTemplateRepository(ref.watch(localStorageServiceProvider));
});

final routineTemplateListProvider = FutureProvider<List<RoutineTemplate>>((ref) {
  return ref.watch(routineTemplateRepositoryProvider).getTemplates();
});

final routineTemplateActionsProvider = Provider((ref) => RoutineTemplateActions(ref));

class RoutineTemplateActions {
  RoutineTemplateActions(this._ref);

  final Ref _ref;

  Future<void> addTemplate(RoutineTemplate template) async {
    await _ref.read(routineTemplateRepositoryProvider).saveTemplate(template);
    _ref.invalidate(routineTemplateListProvider);
  }
}
