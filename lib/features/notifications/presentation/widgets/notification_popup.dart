import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/notification_providers.dart';
import '../../domain/app_notification.dart';
import 'notification_card.dart';

/// 알림 팝업을 [navigator] 위에 띄운다. [fromBell]이면 홈 상단 벨 바로 아래
/// (꼬리가 벨을 가리킴)에, 아니면 화면 맨 위(토스트를 눌렀을 때)에 뜬다.
/// 바깥을 누르면 닫힌다.
void showNotificationPopup(NavigatorState navigator, {bool fromBell = false}) {
  navigator.push(_NotificationPopupRoute(fromBell: fromBell));
}

class _NotificationPopupRoute extends PopupRoute<void> {
  _NotificationPopupRoute({required this.fromBell});

  final bool fromBell;

  @override
  Color? get barrierColor => null; // 배경을 어둡게 하지 않는다.

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '알림 닫기';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    return _NotificationPopup(fromBell: fromBell);
  }
}

/// 최근 알림을 위에서부터 "쭉 쭉" 차례로 내려오듯 보여주는 팝업.
class _NotificationPopup extends ConsumerStatefulWidget {
  const _NotificationPopup({required this.fromBell});

  final bool fromBell;

  @override
  ConsumerState<_NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends ConsumerState<_NotificationPopup>
    with SingleTickerProviderStateMixin {
  static const _maxItems = 5;
  static const _stagger = 90; // ms
  late final AnimationController _controller;
  List<AppNotification> _items = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // 열면 토스트는 치운다. initState는 위젯을 그리는 중이라 provider를 바로 바꿀 수
    // 없어서(예외), 그리기가 끝난 뒤로 미룬다.
    Future(() {
      if (mounted) ref.read(incomingNotificationProvider.notifier).state = null;
    });
    _load();
  }

  Future<void> _load() async {
    final list = await ref.read(notificationListProvider.future);
    if (!mounted) return;
    final items = list.take(_maxItems).toList();
    setState(() => _items = items);
    // 카드 수(+ "이전 알림 기록 보기")만큼 차례로 나타나게 한다.
    _controller.duration = Duration(milliseconds: _stagger * (items.length + 1) + 300);
    _controller.forward();
    await ref.read(notificationRepositoryProvider).markAllRead();
    if (mounted) ref.invalidate(notificationListProvider);
  }

  Future<void> _dismiss(AppNotification n) async {
    setState(() => _items = _items.where((e) => e.id != n.id).toList());
    await ref.read(notificationRepositoryProvider).remove(n.id);
    if (mounted) ref.invalidate(notificationListProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [index]번째 항목이 나타나는 구간(0..1)에 맞춘 슬라이드+페이드.
  Widget _staggered(int index, Widget child) {
    final total = _controller.duration?.inMilliseconds ?? 1;
    final start = (index * _stagger) / total;
    final end = (start + 300 / total).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start.clamp(0.0, 1.0), end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.5), end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + (widget.fromBell ? 60 : 8);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, top, 15, 0),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_items.isEmpty)
                _staggered(
                  0,
                  NotificationCard(
                    pointer: widget.fromBell,
                    notification: AppNotification(
                      id: 'empty',
                      title: '알림',
                      message: '새 알림이 없어요.',
                      createdAt: DateTime.now(),
                    ),
                  ),
                )
              else
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _staggered(
                    i,
                    // 왼쪽으로 밀면 아이폰 알림처럼 사라지고, 기록에서도 지워진다.
                    Dismissible(
                      key: ValueKey(_items[i].id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _dismiss(_items[i]),
                      child: NotificationCard(
                        notification: _items[i],
                        pointer: widget.fromBell && i == 0,
                      ),
                    ),
                  ),
                ],
              const SizedBox(height: 7),
              _staggered(
                _items.length + 1,
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _HistoryButton(
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      router.push('/notifications');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 23,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: NotificationCard.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Text(
          '이전 알림 기록 보기',
          style: TextStyle(color: Color(0xFF898989), fontSize: 10),
        ),
      ),
    );
  }
}
