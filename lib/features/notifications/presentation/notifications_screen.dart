import 'package:flutter/material.dart';

/// 하단 탭바의 "알림" 탭. 홈 화면 종 아이콘을 누르면 뜨던 알림 목록과 같은
/// 내용을 목업에서 확인해서, 그 두 문구를 그대로 정적 데이터로 옮겨뒀다.
///
/// 실제로는 워치에서 오는 이벤트(도움 요청, 미루기 등)를 실시간으로 받아야
/// 하는 화면이라 지금은 진짜 기능이 아니라 "이런 화면이 있다"는 자리표시자에
/// 가깝다. 워치 BLE 연동이 붙으면 이 정적 리스트를 스트림 기반 Provider로
/// 바꿔주면 된다.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _sample = [
    (
      icon: Icons.warning_amber_rounded,
      title: '도움 요청 알림',
      subtitle: '사용자가 도움을 요청했어요',
      time: '1분 전',
    ),
    (
      icon: Icons.snooze_outlined,
      title: '미루기 알림',
      subtitle: '오늘 아침 루틴의 세부 목표를 5분 미뤘어요',
      time: '3분 전',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListView.builder(
        itemCount: _sample.length,
        itemBuilder: (context, index) {
          final item = _sample[index];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            trailing: Text(item.time, style: Theme.of(context).textTheme.bodySmall),
          );
        },
      ),
    );
  }
}
