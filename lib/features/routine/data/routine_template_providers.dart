import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../../children/data/child_providers.dart';
import '../domain/routine_template.dart';
import 'routine_template_repository.dart';

final routineTemplateRepositoryProvider = Provider<RoutineTemplateRepository>((ref) {
  return ApiRoutineTemplateRepository(ref.watch(apiClientProvider));
});

/// 지금 보는 자녀의 저장된 양식 목록. 자녀가 아직 없으면(로딩·미등록) 빈 목록.
/// **`autoDispose`**라서 "템플릿 사용" 화면에 들어올 때마다 서버에서 새로 받는다.
final routineTemplateListProvider =
    FutureProvider.autoDispose<List<RoutineTemplate>>((ref) async {
  final child = ref.watch(currentChildProvider);
  if (child == null) return const [];
  return ref.watch(routineTemplateRepositoryProvider).getTemplates(childId: child.childId);
});

final routineTemplateActionsProvider = Provider((ref) => RoutineTemplateActions(ref));

class RoutineTemplateActions {
  RoutineTemplateActions(this._ref);

  final Ref _ref;

  /// 지금 보는 자녀의 양식으로 저장한다.
  Future<void> addTemplate({
    required String title,
    required String startTime,
    required String endTime,
    required List<String> steps,
  }) async {
    final child = _ref.read(currentChildProvider);
    if (child == null) {
      throw const ApiException(
        code: 'NO_CHILD',
        message: '등록된 자녀가 없어요. 먼저 자녀를 등록해 주세요.',
      );
    }
    await _ref.read(routineTemplateRepositoryProvider).createTemplate(
          childId: child.childId,
          title: title,
          startTime: startTime,
          endTime: endTime,
          steps: steps,
        );
    _ref.invalidate(routineTemplateListProvider);
  }

  Future<void> deleteTemplate(int templateId) async {
    await _ref.read(routineTemplateRepositoryProvider).deleteTemplate(templateId: templateId);
    _ref.invalidate(routineTemplateListProvider);
  }
}
