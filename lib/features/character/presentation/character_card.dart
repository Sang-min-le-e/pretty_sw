import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/character_providers.dart';
import '../domain/companion_character.dart';

/// 대시보드에 붙이는 캐릭터 카드. 실제 캐릭터 일러스트가 아직 없어서,
/// 성장 단계를 색이 진해지는 원(circle avatar)과 이모지로 임시 표현했다.
/// 나중에 디자인팀 캐릭터 에셋이 나오면 이 위젯의 body만 갈아끼우면 된다 —
/// [CompanionCharacter] 모델이나 이 위젯을 쓰는 쪽(대시보드) 코드는 안 바뀐다.
class CharacterCard extends ConsumerWidget {
  const CharacterCard({super.key});

  static const _stageEmojis = ['🥚', '🐣', '🐥', '🐤', '🐔'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(companionCharacterProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: characterAsync.when(
          data: (character) {
            final emoji =
                _stageEmojis[character.growthStage.clamp(0, _stageEmojis.length - 1)];
            return Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('성장 단계 ${character.growthStage}', style: Theme.of(context).textTheme.titleLarge),
                      Text('먹이 준 횟수: ${character.feedCount}회'),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('캐릭터 정보를 불러오지 못했어요: $error'),
        ),
      ),
    );
  }
}
