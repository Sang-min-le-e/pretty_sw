import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/routine_providers.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 루틴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.watch),
            tooltip: '워치 연결',
            onPressed: () => context.push('/watch-connection'),
          ),
        ],
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return const Center(child: Text('아직 등록된 루틴이 없어요'));
          }
          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return ListTile(
                title: Text(routine.title),
                subtitle: Text('${routine.steps.length}단계'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('불러오기 실패: $error')),
      ),
    );
  }
}
