import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'child_repository.dart';

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ApiChildRepository(ref.watch(apiClientProvider));
});
