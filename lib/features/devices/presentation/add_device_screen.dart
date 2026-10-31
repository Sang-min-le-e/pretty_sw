import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/pairing_glow.dart';
import '../../../core/network/api_exception.dart';
import '../../home/presentation/widgets/device_overview.dart';
import '../../watch_connection/data/watch_connection_providers.dart';
import '../data/device_providers.dart';
import 'widgets/labeled_field_row.dart';

/// Figma: 예소 / "8-6 기기 추가하기" (node-id 405:6823, 405:6897, "앱 초안
/// 3" 프레임 안). "기기 관리" 그리드의 점선 카드를 누르면 도착한다.
///
/// 두 단계로 구성된다: (1) 주변 BLE 기기를 찾아 하나 고르는 화면, (2) 기기 이름과
/// 기기가 붙을 WIFI 정보를 입력하는 화면. "추가 완료"를 누르면 서버에서 페어링 코드를
/// 받아 BLE로 기기에 넘기고, 기기가 서버에 등록돼 `ACTIVE`가 될 때까지 기다린다
/// (`DeviceActions.pairNewDevice`).
class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  int _step = 0;
  DiscoveredDevice? _selected;
  bool _pairing = false;
  bool _disposed = false;
  String _progress = '';
  final _nameController = TextEditingController();
  final _wifiIdController = TextEditingController(text: 'U+Net1024');
  final _wifiPwController = TextEditingController();

  @override
  void dispose() {
    _disposed = true;
    _nameController.dispose();
    _wifiIdController.dispose();
    _wifiPwController.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final device = _selected;
    final name = _nameController.text.trim();
    final ssid = _wifiIdController.text.trim();
    if (device == null) return;
    if (name.isEmpty || ssid.isEmpty) {
      _snack('기기 이름과 WIFI 이름을 입력해주세요');
      return;
    }
    setState(() {
      _pairing = true;
      _progress = '';
    });
    try {
      await ref.read(deviceActionsProvider).pairNewDevice(
            bleDeviceId: device.id,
            nickname: name,
            ssid: ssid,
            password: _wifiPwController.text,
            isCancelled: () => _disposed,
            onStep: (step) {
              if (!_disposed) setState(() => _progress = step);
            },
          );
      if (!mounted) return;
      _snack('기기를 연결했어요');
      context.go('/devices');
    } on ApiException catch (e) {
      _fail(e.message);
    } on TimeoutException {
      _fail('기기가 시간 안에 연결되지 않았어요. 기기 전원과 WIFI 정보를 확인하고 다시 시도해주세요.');
    } catch (e) {
      _fail('기기 연결에 실패했어요: $e');
    }
  }

  void _fail(String message) {
    if (_disposed) return;
    setState(() => _pairing = false);
    _snack(message);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              // Figma: 제목 글자 윗선이 화면 위에서 69, 화살표는 x=37, 제목은 x=59.
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Row(
                children: [
                  InkResponse(
                    onTap: () {
                      if (_pairing) return;
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
                  const SizedBox(width: 6),
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
              ),
              Expanded(
                child: _step == 0 ? _ScanningStep(
                  selectedId: _selected?.id,
                  onSelect: (d) => setState(() => _selected = d),
                  onNext: _selected == null ? null : () => setState(() => _step = 1),
                ) : _WifiStep(
                  pairing: _pairing,
                  progress: _progress,
                  nameController: _nameController,
                  idController: _wifiIdController,
                  pwController: _wifiPwController,
                  onDone: _pair,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanningStep extends ConsumerStatefulWidget {
  const _ScanningStep({
    required this.selectedId,
    required this.onSelect,
    required this.onNext,
  });

  final String? selectedId;
  final ValueChanged<DiscoveredDevice> onSelect;
  final VoidCallback? onNext;

  @override
  ConsumerState<_ScanningStep> createState() => _ScanningStepState();
}

class _ScanningStepState extends ConsumerState<_ScanningStep> {
  final _found = <String, DiscoveredDevice>{};
  StreamSubscription<DiscoveredDevice>? _sub;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(bleServiceProvider).scanForWatch().listen(
      (d) => setState(() => _found[d.id] = d),
      onError: (Object e) => setState(() => _error = e),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Figma 8-6: 바깥 빛 무리(252)의 윗선이 화면 위에서 248, 기기(121x163)는
        // 그 중심에 놓인다.
        const SizedBox(height: 148),
        Center(
          child: PairingGlow(
            color: const Color(0xFF4ABEFF),
            child: const DeviceAvatar(
              'assets/images/device_tomo_green.svg',
              width: 121,
              height: 163,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Figma에는 안내 문구가 없다. 오류나 기기 선택 안내처럼 사용자가 알아야
        // 하는 경우에만 보여주고, 평소 "찾는 중" 상태에서는 숨긴다.
        if (_error != null || _found.isNotEmpty)
          Text(
            _error != null
                ? '블루투스를 사용할 수 없어요. 설정에서 블루투스 권한을 확인해주세요.'
                : '연결할 기기를 선택해주세요',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kDeviceOverviewLabelColor, fontSize: 15),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final d in _found.values)
                ListTile(
                  title: Text(d.name.isEmpty ? '(이름 없음)' : d.name),
                  subtitle: Text(d.id),
                  trailing: d.id == widget.selectedId
                      ? const Icon(Icons.check_circle, color: kDeviceOverviewBrandBlue)
                      : null,
                  onTap: () => widget.onSelect(d),
                ),
            ],
          ),
        ),
        // Figma: 303x56 버튼이 가운데에 있고 화면 아래에서 47 떨어져 있다.
        Center(
          child: SizedBox(
            width: 303,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: kDeviceOverviewBrandBlue,
                foregroundColor: Colors.white,
                // Figma는 항상 파란색이다. 기기를 고르기 전에는 눌러도 반응하지 않는다.
                disabledBackgroundColor: kDeviceOverviewBrandBlue,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Text('다음', style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
        const SizedBox(height: 13),
      ],
    );
  }
}

class _WifiStep extends StatelessWidget {
  const _WifiStep({
    required this.nameController,
    required this.idController,
    required this.pwController,
    required this.pairing,
    required this.progress,
    required this.onDone,
  });

  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController pwController;
  final bool pairing;
  final String progress;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        // 홈 화면과 기기 관리 화면이 이 기기를 누구 것으로 표시할지 정하는
        // 별칭(서버의 nickname)이다.
        LabeledFieldRow(
          label: '기기 이름',
          controller: nameController,
          hint: '예: 지예',
        ),
        const SizedBox(height: 12),
        LabeledFieldRow(label: 'WIFI 선택', controller: idController, trailingChevron: true),
        const SizedBox(height: 12),
        LabeledFieldRow(
          label: '비밀번호 입력',
          controller: pwController,
          hint: '입력하세요....',
          obscure: true,
        ),
        const Spacer(),
        if (pairing) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          Text(
            progress,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kDeviceOverviewLabelColor, fontSize: 14),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: pairing ? null : onDone,
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
