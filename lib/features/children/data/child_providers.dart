import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (riverpod 3부터 별도 export)

import '../../auth/data/auth_providers.dart';
import '../domain/child.dart';
import 'child_repository.dart';

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ApiChildRepository(ref.watch(apiClientProvider));
});

/// 내 자녀 목록(`GET /children`). 서버가 원본이라 기기에 따로 저장하지 않고,
/// 자녀를 등록하거나(온보딩) 다른 계정으로 로그인하면 `ref.invalidate`로
/// 다시 받아온다.
final childListProvider = FutureProvider<List<Child>>((ref) {
  return ref.watch(childRepositoryProvider).getChildren();
});

/// 사용자가 자녀 선택 칩에서 고른 자녀의 id. 아직 아무것도 안 골랐으면
/// `null`이고, 이때는 [currentChildProvider]가 목록의 첫 자녀를 대신 쓴다.
/// 기기에 저장하지 않아서 앱을 다시 켜면 첫 자녀로 돌아간다.
final selectedChildIdProvider = StateProvider<int?>((ref) => null);

/// 지금 화면들이 기준으로 삼는 자녀. 고른 자녀가 목록에 없거나(삭제됨) 아직
/// 안 골랐으면 첫 번째 자녀, 목록이 비었거나 아직 불러오는 중이면 `null`.
/// 루틴·기기 같은 "자녀별" API(`/children/:childId/...`)가 이 값을 쓴다.
final currentChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(childListProvider).value ?? const [];
  if (children.isEmpty) return null;
  final selectedId = ref.watch(selectedChildIdProvider);
  for (final child in children) {
    if (child.childId == selectedId) return child;
  }
  return children.first;
});
