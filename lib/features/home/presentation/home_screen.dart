import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../devices/data/device_providers.dart';
import '../../devices/domain/connected_device.dart';
import '../../notifications/data/notification_providers.dart';
import 'widgets/device_overview.dart';

/// Figma: 예소 / 홈화면 (node-id 392:5304, "앱 초안 3" 프레임 안).
///
/// 로그인/온보딩을 마친 뒤 도착하는 홈 화면. 내 기기 상태, 연결된 기기
/// 카드, 현재 루틴 카드를 보여준다.
///
/// 상단 바(로고+벨) 아래 "OO의 기기" 제목부터 "현재 루틴" 카드까지는
/// 기기 상세 관리 화면(`DeviceDetailScreen`, node 405:6598)과 완전히
/// 똑같은 디자인이라 `widgets/device_overview.dart`에 공용 위젯으로
/// 빼뒀다 — 이 파일은 그 공용 위젯들을 어떤 순서로 배치할지와, 이 화면
/// 고유의 상단 바만 담당한다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFFF4F4F4); // 화면 배경(연회색)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // 화면 내용이 기기 높이보다 길어질 수 있어서(작은 화면 대비)
      // SingleChildScrollView로 감싸 세로 스크롤이 가능하게 했다.
      body: SingleChildScrollView(
        child: Column(
          // stretch: 자식 위젯들이 가로 폭을 화면 전체로 꽉 채우게 한다.
          // (흰색 상단 바가 화면 좌우 끝까지 닿아야 하기 때문)
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(), // 맨 위 흰 배경 바: 로고 + 알림 벨
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 24),
              child: _DeviceHeroSection(),
            ),
          ],
        ),
      ),
      // 하단 탭바는 4개 화면(홈/루틴/기기/내 정보)이 공유하는 위젯이라
      // 별도 파일(app/widgets/bottom_nav_bar.dart)로 빼뒀다.
      // currentIndex: 0 은 "지금 홈 탭이 선택된 상태"라는 뜻으로, 홈 아이콘이
      // 파란색으로, 나머지는 회색으로 그려지게 한다.
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

/// "OO의 기기" 제목부터 "현재 루틴" 카드까지 전부. [deviceListProvider]가
/// 비어 있으면(실제로 페어링한 기기가 하나도 없으면) 제목/상태/캐러셀/
/// "기기 상태" 헤더를 [NoConnectedDeviceHero] 안내로 바꾼다 — 실제로
/// 있지도 않은 기기의 이름/배터리/온라인 상태를 보여줄 수는 없기
/// 때문이다. 다만 "연결된 기기" 카드(자체 빈 상태가 있다)와 "현재 루틴"
/// 카드는 기기 유무와 무관하게 항상 보여준다 — 특정 기기를 조회하는
/// 구역이 아니라 계정 전체를 관리/요약하는 카드들이라서다.
class _DeviceHeroSection extends ConsumerWidget {
  const _DeviceHeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider).value ?? const [];

    return Column(
      children: [
        if (devices.isEmpty)
          NoConnectedDeviceHero(
            onAddDevice: () => context.push('/devices/add'),
          )
        else
          _SelectedDevicePanel(devices: devices),
        const SizedBox(height: 24),
        // "연결된 기기" 카드 + "현재 루틴" 카드, 세로로 나란히
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              ConnectedDevicesCard(
                onTap: () => context.push('/connected-devices'),
              ),
              const SizedBox(height: 12),
              const CurrentRoutineCard(),
            ],
          ),
        ),
      ],
    );
  }
}

/// 지금 선택된 기기의 제목/상태/캐러셀 + "기기 상태" 헤더. 기기가 1개
/// 이상 있을 때만 그려진다([_DeviceHeroSection] 참고).
class _SelectedDevicePanel extends ConsumerWidget {
  const _SelectedDevicePanel({required this.devices});

  final List<ConnectedDevice> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 기기가 삭제돼 목록이 줄어든 뒤에도 이전에 보고 있던 인덱스가 범위
    // 밖일 수 있어서(예: 3개 중 3번째를 보다가 1개로 줄어듦), clamp로
    // 항상 유효한 범위로 감싼다. 더 이상 순환(맨 끝 다음 처음으로)하지
    // 않으므로 나머지 연산 대신 clamp를 쓴다.
    final rawIndex = ref.watch(selectedDeviceIndexProvider);
    final index = rawIndex.clamp(0, devices.length - 1);
    final device = devices[index];
    // 등록 순서상 맨 앞/맨 끝이면 그 방향으로는 더 넘길 기기가 없다.
    final canGoPrev = index > 0;
    final canGoNext = index < devices.length - 1;

    return Column(
      // DeviceStatusList는 내용물 너비만큼만 차지하는 Column이라, 기본
      // center 정렬이면 제목 밑에서 붕 떠서 가운데로 몰린다. start로
      // 바꿔서 제목과 같은 왼쪽 기준선에 붙인다(제목/캐러셀/상태 헤더는
      // 전부 가로로 꽉 차는 Row라 이 변경에 영향받지 않는다).
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: DeviceTitleRow(deviceOwnerName: device.name),
        ),
        const SizedBox(height: 4),
        // 온라인 / 연결됨 / 배터리 상태 3줄. 실제 BLE 텔레메트리가 아직
        // 연결되지 않아서(CLAUDE.md 참고), "목록에 있으면 온라인"이라는
        // 가정하에 고정값을 보여준다.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 38),
          child: DeviceStatusList(),
        ),
        const SizedBox(height: 20),
        // 로봇 기기 아바타 + 좌우 이전/다음 화살표. 등록 순서를 따라
        // [selectedDeviceIndexProvider]를 움직인다 — 맨 앞/끝에서는
        // 더 넘길 기기가 없으므로 화살표가 회색으로 바뀌고 눌러도
        // 반응하지 않는다(순환하지 않음).
        DeviceCarousel(
          iconAsset: deviceIconAssetFor(index),
          canGoPrev: canGoPrev,
          canGoNext: canGoNext,
          onPrev: canGoPrev
              ? () => ref.read(selectedDeviceIndexProvider.notifier).state = index - 1
              : null,
          onNext: canGoNext
              ? () => ref.read(selectedDeviceIndexProvider.notifier).state = index + 1
              : null,
        ),
        const SizedBox(height: 48),
        // "기기 상태" 소제목 + "3분전 동기화됨" 캡션
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: DeviceStatusHeaderRow(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// 화면 맨 위, 흰 배경의 상단 바. Tomo 로고(좌) + 알림 벨(우).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // 상태 표시줄(시계·배터리 아이콘) 영역과 겹치지 않도록 SafeArea로
      // 감싼다. bottom: false 는 "아래쪽 안전 영역은 신경 안 써도 된다"는
      // 뜻(이 바는 화면 맨 위에 있으니까).
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(31, 16, 31, 16),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/home_logo.svg', height: 30),
              // Spacer: 남은 가로 공간을 전부 차지해서, 로고는 왼쪽 끝에
              // 알림 벨은 오른쪽 끝에 붙게 밀어준다.
              const Spacer(),
              const _NotificationBellButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 알림 벨 아이콘 + 우측 상단에 겹쳐진 빨간 알림 개수 뱃지.
/// [notificationCountProvider]가 0이면 뱃지 자체를 안 그린다 — 지금은
/// 알림을 발생시키는 기능이 없어서 항상 이 상태다. 뱃지가 벨 아이콘
/// 바깥으로 살짝 삐져나오게 그려야 해서 Stack + Positioned를 쓴다(일반
/// Row/Column으로는 이렇게 "겹치는" 배치를 할 수 없다).
class _NotificationBellButton extends ConsumerWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider);

    return InkResponse(
      onTap: () {}, // 알림 화면이 아직 없어서 지금은 반응 없음
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          // clipBehavior: Clip.none 을 줘야 Positioned로 벨 바깥까지
          // 나간 뱃지가 잘리지 않고 다 보인다(기본값은 자식이 부모
          // 영역 밖으로 나가면 잘라내 버림).
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              'assets/images/home_bell.svg',
              width: 22,
              height: 21,
            ),
            if (count > 0)
              Positioned(
                // 벨 아이콘 기준 왼쪽 위로 살짝 벗어난 위치(음수 값)에
                // 뱃지를 겹쳐 그린다.
                top: -5,
                right: -6,
                child: Container(
                  width: 13,
                  height: 13,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE71A1A),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
