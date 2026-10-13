import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../home/presentation/widgets/device_overview.dart';

/// Figma: 예소 / 앱 최종 / iPhone 17 - 93 (node-id 508:5897). "연결된 기기"
/// 화면(92)에서 연결된 기기가 하나도 없을 때 "연결된 기기" 카드를 누르면
/// 도착한다.
///
/// 화면에는 "공유 기기 추가" 카드 하나뿐이고, 누르면 기기 추가 화면
/// (`/devices/add`)으로 넘어간다.
class ConnectedDevicesEmptyScreen extends StatelessWidget {
  const ConnectedDevicesEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목 글자 왼쪽 끝이 화면 왼쪽에서 59px(Figma)에 오도록 맞춘 여백.
            Padding(
              padding: const EdgeInsets.only(left: 31, top: 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BackHeader(
                  title: '연결된 기기',
                  chevronColor: const Color(0xFFA9A9A9),
                  onBack: () => context.pop(),
                ),
              ),
            ),
            const SizedBox(height: 29),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/devices/add'),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  decoration: deviceCardDecoration(),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/connected_devices_add_plus.svg',
                        width: 15,
                        height: 15,
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        '공유 기기 추가',
                        style: TextStyle(
                          color: kDeviceOverviewStatusColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
