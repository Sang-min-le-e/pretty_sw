import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/watch_connection_providers.dart';

class WatchConnectionScreen extends ConsumerWidget {
  const WatchConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanResults = ref.watch(watchScanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('워치 연결')),
      body: scanResults.when(
        data: (device) => ListTile(
          title: Text(device.name.isEmpty ? '(이름 없음)' : device.name),
          subtitle: Text(device.id),
        ),
        loading: () => const Center(child: Text('주변 기기를 스캔 중이에요...')),
        error: (error, stack) => Center(child: Text('스캔 실패: $error')),
      ),
    );
  }
}
