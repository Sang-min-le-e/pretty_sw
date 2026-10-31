import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../data/notification_providers.dart';
import '../domain/app_notification.dart';

/// 홈 벨 아이콘을 누르면 열리는 알림 목록. 기기에서 할 일을 완료했다는 알림이
/// 최신순으로 쌓인다. 화면을 열면 모두 읽음 처리해서 벨 뱃지가 사라진다 —
/// 이 화면에서는 방금 읽음 처리된 알림도 "새 알림"(점)으로 보이도록, 열 때의
/// 읽음 상태를 한 번 붙잡아 둔다.
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  Set<String>? _unreadOnOpen;
  final _removed = <String>{}; // 이 화면에서 밀어서 지운 알림(목록이 다시 로드되기 전까지 가린다)

  @override
  void initState() {
    super.initState();
    _markReadWhenLoaded();
  }

  Future<void> _markReadWhenLoaded() async {
    final list = await ref.read(notificationListProvider.future);
    if (!mounted) return;
    setState(
      () => _unreadOnOpen = {
        for (final n in list)
          if (!n.read) n.id,
      },
    );
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(notificationListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 31, top: 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BackHeader(
                  title: '알림',
                  chevronColor: const Color(0xFFA9A9A9),
                  onBack: () => context.pop(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notifications.when(
                data: (all) {
                  final list = all
                      .where((n) => !_removed.contains(n.id))
                      .toList();
                  return list.isEmpty
                      ? const Center(
                          child: Text(
                            '새 알림이 없어요',
                            style: TextStyle(color: Color(0xFFA9A9A9)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 19),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => Dismissible(
                            key: ValueKey(list[i].id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              final id = list[i].id;
                              setState(() => _removed.add(id));
                              await ref
                                  .read(notificationRepositoryProvider)
                                  .remove(id);
                              if (mounted) {
                                ref.invalidate(notificationListProvider);
                              }
                            },
                            child: _NotificationTile(
                              notification: list[i],
                              isNew:
                                  _unreadOnOpen?.contains(list[i].id) ??
                                  !list[i].read,
                            ),
                          ),
                        );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('알림을 불러오지 못했어요: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.isNew});

  final AppNotification notification;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNew ? const Color(0xFFE71A1A) : Colors.transparent,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeLabel(notification.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA9A9A9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? '오전' : '오후';
    final min = t.minute.toString().padLeft(2, '0');
    return '${t.month}월 ${t.day}일 $ampm $hour:$min';
  }
}
