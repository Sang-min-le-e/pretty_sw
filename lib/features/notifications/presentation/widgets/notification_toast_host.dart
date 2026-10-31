import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../data/notification_providers.dart';
import '../../domain/app_notification.dart';
import 'notification_card.dart';
import 'notification_popup.dart';

/// 앱 전체 화면 위에 새 알림 토스트를 얹는 래퍼(`MaterialApp.router`의 `builder`에서
/// 사용). 새 알림이 오면 위에서 내려와 3초 뒤 다시 올라가고, 누르면 알림 팝업이 열린다.
class NotificationToastHost extends ConsumerStatefulWidget {
  const NotificationToastHost({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<NotificationToastHost> createState() => _NotificationToastHostState();
}

class _NotificationToastHostState extends ConsumerState<NotificationToastHost> {
  static const _visibleFor = Duration(seconds: 3);
  static const _slide = Duration(milliseconds: 300);

  AppNotification? _shown;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show(AppNotification n) {
    _hideTimer?.cancel();
    setState(() {
      _shown = n;
      _visible = true;
    });
    _hideTimer = Timer(_visibleFor, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  void _open() {
    _hide();
    final navigator = appRouter.routerDelegate.navigatorKey.currentState;
    if (navigator != null) showNotificationPopup(navigator);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingNotificationProvider, (prev, next) {
      if (next != null) _show(next);
    });

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 15,
          right: 15,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedSlide(
              duration: _slide,
              curve: Curves.easeOutCubic,
              offset: _visible ? Offset.zero : const Offset(0, -1.8),
              child: AnimatedOpacity(
                duration: _slide,
                opacity: _visible ? 1 : 0,
                child: _shown == null
                    ? const SizedBox.shrink()
                    // 왼쪽으로 밀면 토스트만 치운다(알림 기록은 그대로).
                    : Dismissible(
                        key: ValueKey(_shown!.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          _hideTimer?.cancel();
                          setState(() {
                            _shown = null;
                            _visible = false;
                          });
                        },
                        child: GestureDetector(
                          onTap: _open,
                          child: Material(
                            type: MaterialType.transparency,
                            child: NotificationCard(notification: _shown!),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
