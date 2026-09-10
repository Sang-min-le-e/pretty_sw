import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../home/presentation/widgets/device_overview.dart';

/// Figma: 예소 / "8-1 기기 관리 상세" (node-id 405:6598, "앱 초안 3" 프레임
/// 안). "기기 관리" 그리드 화면에서 기기 카드 하나를 누르면 도착한다.
///
/// 상단 바(뒤로가기 + "상세 기기 관리" + 설정 톱니바퀴)와, 캐러셀 아래
/// 페이지네이션 점만 빼면 홈 화면과 완전히 같은 레이아웃이라
/// `widgets/device_overview.dart`의 공용 위젯을 그대로 재사용한다.
class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({super.key, required this.deviceOwnerName});

  final String deviceOwnerName;

  static const _bg = Color(0xFFF4F4F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: _DetailTopBar(
                  onBack: () => context.pop(),
                  onSettings: () => context.push('/devices/$deviceOwnerName/settings'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  // DeviceStatusList는 내용물 너비만큼만 차지하는 Column이라,
                  // 기본 center 정렬이면 제목 밑에서 가운데로 몰린다. start로
                  // 바꿔서 제목과 같은 왼쪽 기준선에 붙인다 — 대신 원래
                  // 가운데 있던 페이지네이션 점만 Center로 따로 감싸서
                  // 그대로 가운데에 남긴다(그 외엔 전부 가로로 꽉 차는
                  // Row/Container라 이 변경에 영향받지 않는다).
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 38),
                      child: DeviceTitleRow(deviceOwnerName: deviceOwnerName),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 38),
                      child: DeviceStatusList(
                        onWifiTap: () =>
                            context.push('/devices/$deviceOwnerName/wifi'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const DeviceCarousel(),
                    const SizedBox(height: 12),
                    const Center(child: DevicePaginationDots()),
                    const SizedBox(height: 36),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: DeviceStatusHeaderRow(),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          ConnectedDevicesCard(
                            onTap: () => context.push('/connected-devices'),
                          ),
                          const SizedBox(height: 12),
                          const CurrentRoutineCard(),
                          const SizedBox(height: 12),
                          _StatsEntryCard(
                            onTap: () =>
                                context.push('/devices/$deviceOwnerName/stats'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

/// 뒤로가기 화살표 + "상세 기기 관리" 제목 + 설정 톱니바퀴("기기 설정"
/// 화면으로 이동).
class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkResponse(
          onTap: onBack,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                'assets/images/home_chevron_prev.svg',
                width: 14,
                height: 8,
                colorFilter: const ColorFilter.mode(
                  kDeviceOverviewLabelColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '상세 기기 관리',
          style: TextStyle(
            color: kDeviceOverviewLabelColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        InkResponse(
          onTap: onSettings,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SvgPicture.asset(
              'assets/images/home_gear.svg',
              width: 20,
              height: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// "OO의 하루/일주일/한달 통계" 화면으로 이동하는 카드. 다른 카드들과
/// 같은 흰 배경 + 그림자 스타일을 쓰되, 내용은 안내 문구 하나뿐이다.
class _StatsEntryCard extends StatelessWidget {
  const _StatsEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        decoration: deviceCardDecoration(),
        padding: const EdgeInsets.fromLTRB(23, 16, 15, 16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '루틴 통계 보기',
                style: TextStyle(
                  color: kDeviceOverviewLabelColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            RotatedBox(
              quarterTurns: 1,
              child: SvgPicture.asset(
                'assets/images/home_chevron_small.svg',
                width: 7,
                height: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
