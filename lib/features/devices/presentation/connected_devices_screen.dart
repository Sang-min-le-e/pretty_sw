import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../home/presentation/widgets/device_overview.dart';
import '../data/device_providers.dart';
import '../data/wifi_credentials.dart';

/// Figma: 예소 / 앱 최종 / iPhone 17 - 92 (node-id 508:5859). 홈 화면과 기기
/// 상세 화면의 "연결된 기기" 카드를 누르면 도착한다.
///
/// 위에서부터 WIFI ID, PW, 그리고 "연결된 기기" 카드([ConnectedDevicesCard])가
/// 쌓인다. 와이파이 값은 마지막으로 기기를 추가할 때 입력해 기기에 넘긴 값이다
/// ([wifiCredentialsProvider]) — iOS가 지금 붙은 와이파이의 비밀번호를 앱에
/// 주지 않아서 읽어 올 수가 없다. 한 번도 추가한 적이 없으면 "-"로 보인다.
class ConnectedDevicesScreen extends ConsumerWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifi = ref.watch(wifiCredentialsProvider).value;
    final hasDevices = (ref.watch(deviceListProvider).value ?? const []).isNotEmpty;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WifiInfoRow(label: 'WIFI ID', value: _orDash(wifi?.ssid)),
                  const SizedBox(height: 11),
                  _WifiInfoRow(label: 'PW', value: _orDash(wifi?.password)),
                  const SizedBox(height: 11),
                  // 기기가 없으면 "공유 기기 추가" 화면(93)으로 간다. 기기가 있을
                  // 때 가야 할 기기별 연결 상태 화면(95)은 아직 없어서 기기 탭으로
                  // 보낸다.
                  ConnectedDevicesCard(
                    onTap: () => hasDevices
                        ? context.go('/devices')
                        : context.push('/connected-devices/empty'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _orDash(String? value) =>
      (value == null || value.isEmpty) ? '-' : value;
}

/// "WIFI ID  U+Net1024"처럼 라벨과 값을 한 줄로 보여 주는 흰 카드(높이 56).
class _WifiInfoRow extends StatelessWidget {
  const _WifiInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 27),
      decoration: deviceCardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                color: kDeviceOverviewLabelColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kDeviceOverviewCaptionColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
