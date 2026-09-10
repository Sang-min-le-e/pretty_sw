import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';
import '../../home/presentation/widgets/device_overview.dart';
import '../data/device_providers.dart';

/// Figma: 예소 / "연결된 기기" 추가 흐름 (node-id 392:5243 / 392:5255 /
/// 392:5275, "앱 초안 3" 프레임 안, 이름 없는 "iPhone 17 - 73/74/75"
/// 프레임으로 저장돼 있었다). [ConnectedDevicesScreen]의 "+ 연결 기기
/// 추가"를 누르면 도착한다.
///
/// 2단계: (1) 상대방이 알려준 기기 아이디를 입력 → (2) 그 아이디로 찾은
/// 후보 기기 중 하나를 골라 확정. 실제로는 백엔드에 기기 아이디를 조회할
/// 방법이 없어서, 무엇을 입력하든 항상 같은 예시 기기 3개를 후보로
/// 보여준다 — 그래서 뭘 골라도 실제로 연결되는 기기는 바뀌지 않는다.
class AddConnectedDeviceScreen extends ConsumerStatefulWidget {
  const AddConnectedDeviceScreen({super.key});

  @override
  ConsumerState<AddConnectedDeviceScreen> createState() => _AddConnectedDeviceScreenState();
}

class _AddConnectedDeviceScreenState extends ConsumerState<AddConnectedDeviceScreen> {
  int _step = 0;
  final _idController = TextEditingController();

  static const _candidates = [
    ('지예', 'assets/images/member_device_green.svg'),
    ('예담', 'assets/images/member_device_gray.svg'),
    ('예소', 'assets/images/member_device_purple.svg'),
  ];

  @override
  void dispose() {
    _idController.dispose();
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
              BackHeader(
                title: '연결된 기기',
                onBack: () {
                  if (_step == 1) {
                    setState(() => _step = 0);
                  } else {
                    context.pop();
                  }
                },
              ),
              const SizedBox(height: 24),
              // "연결된 기기" 화면에도 있는 "+ 연결 기기 추가" 알약을 이미
              // 그 흐름을 타고 들어온 이 화면에서는 회색(비활성)으로만
              // 보여준다 — 다시 눌러도 할 일이 없어서 onTap을 주지 않는다.
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: kDeviceOverviewStatusColor, size: 18),
                    SizedBox(width: 8),
                    Text('연결 기기 추가', style: TextStyle(color: kDeviceOverviewStatusColor, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _step == 0
                    ? _IdInputStep(
                        controller: _idController,
                        onNext: () => setState(() => _step = 1),
                      )
                    : _PickDeviceStep(
                        candidates: _candidates,
                        onPicked: (name) async {
                          await ref.read(deviceActionsProvider).addDevice(name);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('기기를 연결했어요')),
                          );
                          context.pop();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdInputStep extends StatelessWidget {
  const _IdInputStep({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4)],
          ),
          child: const Column(
            children: [
              Text(
                '아이디를 입력해세요.',
                style: TextStyle(color: kDeviceOverviewLabelColor, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                '나에게 등록된 기기 번호를 입력',
                style: TextStyle(color: kDeviceOverviewCaptionColor, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: kDeviceOverviewLabelColor, fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '입력하기....',
              hintStyle: TextStyle(color: kDeviceOverviewStatusColor),
            ),
            onSubmitted: (_) => onNext(),
          ),
        ),
        const Spacer(),
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

class _PickDeviceStep extends StatelessWidget {
  const _PickDeviceStep({required this.candidates, required this.onPicked});

  final List<(String, String)> candidates;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final candidate in candidates)
          InkWell(
            onTap: () => onPicked(candidate.$1),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 156,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4)],
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 56, height: 58, child: AssetIcon(candidate.$2)),
                  const SizedBox(height: 6),
                  Text(
                    candidate.$1,
                    style: const TextStyle(
                      color: kDeviceOverviewLabelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
