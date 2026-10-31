import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notification_service.dart';
import '../../auth/data/auth_providers.dart';
import '../../children/data/child_providers.dart';
import '../../routine/data/routine_providers.dart';
import '../domain/app_notification.dart';
import 'notification_providers.dart';

final localNotificationServiceProvider = Provider((ref) => LocalNotificationService());

/// 아이가 기기에서 할 일을 완료하면 서버에만 반영되고 앱에는 푸시가 오지 않으므로,
/// 앱이 켜져 있는 동안 서버 달력을 주기적으로(그리고 앱으로 돌아올 때) 다시 받아
/// 새로 `DONE`이 된 할 일을 찾아 알림으로 띄운다. 앱이 꺼져 있던 사이의 완료분은
/// 다음에 켤 때 한꺼번에 알린다(본 적 있는 완료 id를 Hive에 저장해 비교).
///
/// 서버 푸시(FCM)가 생기면 이 폴링을 푸시 수신으로 바꾸면 된다.
class CompletionWatcher with WidgetsBindingObserver {
  CompletionWatcher(this._ref, {this.interval = const Duration(seconds: 30)}) {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => check());
    check();
  }

  final Ref _ref;
  final Duration interval;
  late final Timer _timer;
  bool _checking = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> check() async {
    if (_checking) return;
    final child = _ref.read(currentChildProvider);
    if (child == null) return;
    _checking = true;
    try {
      // 로그아웃했으면(저장된 로그인 세션이 없으면) 서버를 부르지 않는다 — 부르면 401만 난다.
      if (await _ref.read(authSessionRepositoryProvider).getAccessUuid() == null) return;
      final today = DateTime.now();
      final routines = await _ref.read(routineRepositoryProvider).getCalendar(
            childId: child.childId,
            from: DateTime(today.year, today.month, today.day),
            to: DateTime(today.year, today.month, today.day),
          );
      final doneNow = <int, ({String routine, String task})>{
        for (final r in routines)
          for (final s in r.smallRoutines)
            if (s.done) s.id: (routine: r.title, task: s.title),
      };

      final repo = _ref.read(notificationRepositoryProvider);
      final seen = await repo.getSeenDoneIds(child.childId);
      if (seen != null) {
        final fresh = doneNow.keys.where((id) => !seen.contains(id)).toList();
        final service = _ref.read(localNotificationServiceProvider);
        final now = DateTime.now();
        final inForeground =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        AppNotification? latest;
        for (final id in fresh) {
          final done = doneNow[id]!;
          final message = '${child.name} · "${done.task}" 완료!';
          latest = AppNotification(
            id: '${child.childId}-$id-${now.microsecondsSinceEpoch}',
            title: '완료 알림',
            message: message,
            createdAt: now,
          );
          await repo.add(latest);
          // 앱이 켜져 있으면 화면 위 토스트로, 아니면 OS 알림으로 알린다.
          if (!inForeground) {
            await service.show(id: id, title: latest.title, body: message);
          }
        }
        if (latest != null) {
          _ref.invalidate(notificationListProvider);
          if (inForeground) _ref.read(incomingNotificationProvider.notifier).state = latest;
        }
      }
      await repo.saveSeenDoneIds(child.childId, {...?seen, ...doneNow.keys});
    } catch (e) {
      debugPrint('완료 확인 실패(다음 주기에 다시 시도): $e');
    } finally {
      _checking = false;
    }
  }
}

/// 홈 화면이 한 번 `watch`하면 앱이 끝날 때까지 계속 감시한다.
final completionWatcherProvider = Provider<CompletionWatcher>((ref) {
  final watcher = CompletionWatcher(ref);
  ref.onDispose(watcher.dispose);
  // 자녀를 바꾸면 그 자녀 기준으로 바로 한 번 확인한다.
  ref.listen(currentChildProvider, (prev, next) {
    if (prev?.childId != next?.childId) watcher.check();
  });
  return watcher;
});
