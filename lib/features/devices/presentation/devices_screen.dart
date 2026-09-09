import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../home/presentation/widgets/device_overview.dart';

/// Figma: 예소 / "8. 기기 관리 기본 화면" (node-id 392:2250, "앱 초안 3"
/// 프레임 안). 하단 탭바의 "기기" 탭 — 등록된 자녀 기기들을 2열 그리드로
/// 보여주고, 카드를 누르면 그 기기의 상세 관리 화면(`DeviceDetailScreen`)
/// 으로 이동한다.
///
/// "기기 추가하기" 점선 카드는 아직 기기 페어링 화면(Figma "8-6")을 만들지
/// 않아서 지금은 눌러도 반응하지 않는다.
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  static const _bg = Color(0xFFF4F4F4);

  // 지금은 실제 기기 등록/삭제 기능이 없어서, 홈 화면의 "연결된 기기"
  // 카드와 같은 세 자녀를 그대로 하드코딩해서 보여준다.
  static const _devices = [
    _DeviceEntry(
      name: '지예',
      iconAsset: 'assets/images/member_device_green.svg',
    ),
    _DeviceEntry(
      name: '예담',
      iconAsset: 'assets/images/member_device_gray.svg',
    ),
    _DeviceEntry(
      name: '예소',
      iconAsset: 'assets/images/member_device_purple.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 20, 36, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '기기 관리',
                    style: TextStyle(
                      color: kDeviceOverviewLabelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Wrap으로 2열 그리드를 만든다. GridView 대신 Wrap을 쓴 건,
                // 카드 개수가 적고(자녀 3명 + 추가 카드) 카드 높이가 고정
                // (157)이라 스크롤 영역 안에서 내용물 높이만큼만 차지하는
                // Wrap이 GridView의 shrinkWrap 설정보다 더 간단하기 때문.
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final device in _devices)
                      _DeviceGridCard(
                        entry: device,
                        onTap: () => context.push('/devices/${device.name}'),
                      ),
                    _AddDeviceGridCard(
                      onTap: () => context.push('/devices/add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

class _DeviceEntry {
  const _DeviceEntry({required this.name, required this.iconAsset});

  final String name;
  final String iconAsset;
}

/// 그리드 카드 한 칸의 공통 크기. 화면 폭(402) - 좌우 패딩(36*2) - 카드
/// 사이 간격(14) 을 2로 나눈 값과 대략 맞춘 고정 폭이다.
const _kCardWidth = 159.5;
const _kCardHeight = 157.0;

/// 등록된 기기 카드 한 장: 로봇 아이콘 + 이름 + 우측 상단 "더보기" 화살표.
class _DeviceGridCard extends StatelessWidget {
  const _DeviceGridCard({required this.entry, required this.onTap});

  final _DeviceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        decoration: deviceCardDecoration(),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: RotatedBox(
                quarterTurns: 1,
                child: SvgPicture.asset(
                  'assets/images/home_chevron_small.svg',
                  width: 7,
                  height: 4,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 86,
                  height: 89,
                  child: AssetIcon(entry.iconAsset),
                ),
              ),
            ),
            Text(
              entry.name,
              style: const TextStyle(
                color: kDeviceOverviewLabelColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "기기 추가하기" 점선 카드.
class _AddDeviceGridCard extends StatelessWidget {
  const _AddDeviceGridCard({required this.onTap});

  final VoidCallback onTap;

  static const _dashedBorderColor = Color(0xFFCACACA);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        // Figma 원본은 점선 테두리지만, Flutter 기본 Border는 점선을
        // 지원하지 않아서(커스텀 페인터 없이는) 실선으로 대체했다 —
        // 자리를 채우는 스텁 카드라 시각적 차이가 크지 않다고 판단.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _dashedBorderColor),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 26,
              height: 24,
              child: AssetIcon('assets/images/device_add_plus.svg'),
            ),
            SizedBox(height: 10),
            Text(
              '기기 추가하기',
              style: TextStyle(color: _dashedBorderColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
