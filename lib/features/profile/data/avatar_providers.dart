import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/local_storage_service.dart';
import 'avatar_repository.dart';

final _localStorageServiceProvider = Provider((ref) => LocalStorageService());

final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  return LocalAvatarRepository(ref.watch(_localStorageServiceProvider));
});

/// 현재 저장된 프로필 사진 경로. 없으면(한 번도 고른 적 없으면) `null`이고,
/// 화면은 이 경우 기본 사람 아이콘을 보여준다.
final avatarPathProvider = FutureProvider<String?>((ref) {
  return ref.watch(avatarRepositoryProvider).getAvatarPath();
});

final avatarActionsProvider = Provider((ref) => AvatarActions(ref));

class AvatarActions {
  AvatarActions(this._ref);

  final Ref _ref;

  /// 갤러리에서 사진을 고르게 하고, 고른 파일을 앱 전용 문서 폴더로
  /// 복사해서 저장한다. 원본 파일(예: 갤러리 캐시)은 앱이 지워지거나
  /// 옮겨지면 사라질 수 있어서, 앱이 계속 읽을 수 있는 안정된 위치로
  /// 복사해두는 것 — 골랐는데 취소하면 `null`을 반환하고 아무것도
  /// 바꾸지 않는다.
  Future<void> pickAndSaveAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    // 매번 같은 파일 이름으로 저장해서 예전 사진을 자연스럽게 덮어쓴다 —
    // 사진을 바꿀 때마다 기기에 파일이 계속 쌓이는 걸 막기 위해서다.
    final savedPath = p.join(docsDir.path, 'profile_avatar${p.extension(picked.path)}');
    await File(picked.path).copy(savedPath);

    await _ref.read(avatarRepositoryProvider).setAvatarPath(savedPath);
    _ref.invalidate(avatarPathProvider);
  }
}
