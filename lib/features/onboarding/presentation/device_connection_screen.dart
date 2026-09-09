import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/pairing_glow.dart';
import 'widgets/step_dots.dart';

/// Figma: 예소 / 앱 초안 / Group 464 (node-id 279:2189) — 초기 설정 3단계(마지막).
///
/// 자녀 정보 다음 단계로, 손목 기기를 페어링하기 전 대기 화면을 보여준다.
/// 실제 BLE 페어링은 아직 이 화면에 연결돼 있지 않아서 "설정 완료"는
/// 곧바로 초기 설정을 마치고 홈으로 이동한다.
class DeviceConnectionScreen extends StatelessWidget {
  const DeviceConnectionScreen({super.key});

  static const _labelColor = Color(0xFF505050);
  static const _brandBlue = Color(0xFF4ABEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.chevron_left, size: 32, color: _labelColor),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/onboarding/child-info'),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: double.infinity,
                child: Text(
                  '기기 연결하기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _labelColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: StepDots(activeIndex: 2)),
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
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('설정 완료', style: TextStyle(fontSize: 22)),
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
