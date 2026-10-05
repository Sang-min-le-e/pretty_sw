import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/child_providers.dart';

/// 자녀 이름을 가로 칩으로 나열해서 지금 보는 자녀를 고르게 하는 줄.
/// 서버의 루틴·기기 API가 전부 자녀별(`/children/:childId/...`)이라, 루틴 탭
/// 맨 위에 두고 고르면 [selectedChildIdProvider]가 바뀌어 그 자녀 기준으로
/// 화면이 다시 그려진다.
///
/// 자녀는 보호자당 최대 10명이라 칩이 화면 폭을 넘을 수 있어서 가로로
/// 스크롤된다. 목록이 비어 있거나 불러오지 못한 경우에는 칩 대신 안내 글을
/// 보여준다.
class ChildSelector extends ConsumerWidget {
  const ChildSelector({super.key});

  static const _captionColor = Color(0xFF7F7F7F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childListProvider);
    final children = async.value;

    // 값이 아직 없다: 오류면 눌러서 다시 시도하게, 로딩이면 칩 높이만큼 비워 둔다
    // (로딩이 짧아서 스피너를 넣으면 오히려 깜빡거린다).
    if (children == null) {
      if (!async.hasError) return const SizedBox(height: 31);
      return GestureDetector(
        onTap: () => ref.invalidate(childListProvider),
        child: const Text(
          '자녀 목록을 불러오지 못했어요. 눌러서 다시 시도',
          style: TextStyle(color: _captionColor, fontSize: 13),
        ),
      );
    }
    if (children.isEmpty) {
      return const Text(
        '등록된 자녀가 없어요',
        style: TextStyle(color: _captionColor, fontSize: 13),
      );
    }

    final current = ref.watch(currentChildProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final child in children) ...[
            if (child != children.first) const SizedBox(width: 6),
            _ChildChip(
              name: child.name,
              active: child.childId == current?.childId,
              onTap: () =>
                  ref.read(selectedChildIdProvider.notifier).state = child.childId,
            ),
          ],
        ],
      ),
    );
  }
}

/// 자녀 한 명을 나타내는 알약 칩. 선택된 칩만 하늘색 배경에 흰 글씨
/// (루틴 추가 폼의 탭 칩과 같은 모양).
class _ChildChip extends StatelessWidget {
  const _ChildChip({required this.name, required this.active, required this.onTap});

  final String name;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(44),
      child: Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4ABEFF) : Colors.white,
          borderRadius: BorderRadius.circular(44),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
          ],
        ),
        child: Text(
          name,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF989898),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
