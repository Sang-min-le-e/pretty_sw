import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../home/presentation/widgets/device_overview.dart';
import 'widgets/labeled_field_row.dart';

/// Figma: 예소 / "연결된 기기" (node-id 392:5220, "앱 초안 3" 프레임 안,
/// 이름 없는 "iPhone 17 - 72" 프레임으로 저장돼 있었다). 홈 화면과 기기
/// 상세 화면의 "연결된 기기" 카드를 누르면 도착한다.
///
/// WIFI 정보(그 WIFI에 새 기기를 연결할 때 필요)와, 지금 연결된 가족
/// 구성원 기기 목록을 보여준다. "+ 연결 기기 추가"는
/// [AddConnectedDeviceScreen](Figma "iPhone 17 - 74/75")으로 이동한다.
class ConnectedDevicesScreen extends StatelessWidget {
  const ConnectedDevicesScreen({super.key});

  static const _members = [
    ('지예님의 기기', Color(0xFFC8E093)),
    ('예담님의 기기', Color(0xFFE1E1E1)),
    ('예소님의 기기', Color(0xFFAA97D0)),
  ];

  @override
  Widget build(BuildContext context) {
    final idController = TextEditingController(text: 'U+Net1024');
    final pwController = TextEditingController(text: '1000006315');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              BackHeader(title: '연결된 기기', onBack: () => context.pop()),
              const SizedBox(height: 24),
              LabeledFieldRow(label: 'WIFI ID', controller: idController),
              const SizedBox(height: 12),
              LabeledFieldRow(label: 'PW', controller: pwController),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => context.push('/connected-devices/add'),
                borderRadius: BorderRadius.circular(21),
                child: Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: kDeviceOverviewBrandBlue, size: 18),
                      SizedBox(width: 8),
                      Text('연결 기기 추가', style: TextStyle(color: kDeviceOverviewBrandBlue, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              if (_members.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '연결된 기기',
                            style: TextStyle(
                              color: kDeviceOverviewLabelColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_members.length}개 기기 연결중',
                            style: const TextStyle(color: kDeviceOverviewCaptionColor, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final member in _members) ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: member.$2, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              member.$1,
                              style: const TextStyle(color: kDeviceOverviewCaptionColor, fontSize: 14),
                            ),
                          ],
                        ),
                        if (member != _members.last) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
