import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../home/presentation/widgets/device_overview.dart';
import 'widgets/labeled_field_row.dart';

/// Figma: 예소 / "8-1-1 와이파이 설정" (node-id 392:2163, "앱 초안 3" 프레임
/// 안). 기기 상세 관리 화면에서 "연결됨"(WIFI) 상태 줄을 누르면 도착한다.
///
/// 실제 WIFI 재설정은 기기와의 BLE 통신이 필요해서 아직 붙어있지 않다 —
/// 지금은 입력값을 보여주고 수정할 수 있는 화면만 만들어뒀고, "완료"는
/// 그냥 이전 화면으로 돌아간다.
class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({super.key});

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  final _idController = TextEditingController(text: 'U+Net1024');
  final _pwController = TextEditingController(text: '1000006315');

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  InkResponse(
                    onTap: () => context.pop(),
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
                    'WIFI',
                    style: TextStyle(
                      color: kDeviceOverviewLabelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LabeledFieldRow(label: 'WIFI ID', controller: _idController),
              const SizedBox(height: 12),
              LabeledFieldRow(label: 'PW', controller: _pwController),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDeviceOverviewBrandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('완료', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
