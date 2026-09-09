import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/pairing_glow.dart';
import '../../home/presentation/widgets/device_overview.dart';
import 'widgets/labeled_field_row.dart';

/// Figma: 예소 / "8-6 기기 추가하기" (node-id 405:6823, 405:6897, "앱 초안
/// 3" 프레임 안). "기기 관리" 그리드의 점선 카드를 누르면 도착한다.
///
/// 두 단계로 구성된다: (1) 기기를 찾는 동안 보여주는 대기 화면, (2) 새
/// 기기가 연결할 WIFI 정보를 입력하는 화면. 실제 BLE 스캔/페어링은 아직
/// `core/ble/ble_service.dart`에 GATT 서비스 UUID가 없어서 연결돼 있지
/// 않다(다른 팀의 스펙 대기 중, CLAUDE.md 참고) — 그래서 1단계는 몇 초
/// 기다리는 척만 하고 바로 "다음"을 누를 수 있게 해둔다.
class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  int _step = 0;
  final _wifiIdController = TextEditingController(text: 'U+Net1024');
  final _wifiPwController = TextEditingController();

  @override
  void dispose() {
    _wifiIdController.dispose();
    _wifiPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    onTap: () {
                      if (_step == 1) {
                        setState(() => _step = 0);
                      } else {
                        context.pop();
                      }
                    },
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
                    '기기 추가하기',
                    style: TextStyle(
                      color: kDeviceOverviewLabelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _step == 0 ? _ScanningStep(onNext: () => setState(() => _step = 1)) : _WifiStep(
                  idController: _wifiIdController,
                  pwController: _wifiPwController,
                  onDone: () => context.go('/devices'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanningStep extends StatelessWidget {
  const _ScanningStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 3),
        Center(
          child: PairingGlow(
            child: SizedBox(
              width: 143,
              height: 149,
              child: SvgPicture.asset('assets/images/device_icon.svg'),
            ),
          ),
        ),
        const Spacer(flex: 4),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: kDeviceOverviewBrandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text('다음', style: TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _WifiStep extends StatelessWidget {
  const _WifiStep({
    required this.idController,
    required this.pwController,
    required this.onDone,
  });

  final TextEditingController idController;
  final TextEditingController pwController;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        LabeledFieldRow(label: 'WIFI 선택', controller: idController, trailingChevron: true),
        const SizedBox(height: 12),
        LabeledFieldRow(
          label: '비밀번호 입력',
          controller: pwController,
          hint: '입력하세요....',
          obscure: true,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: kDeviceOverviewBrandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text('추가 완료', style: TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
