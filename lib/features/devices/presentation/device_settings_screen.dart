import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../home/presentation/widgets/device_overview.dart';
import '../data/device_providers.dart';

/// Figma: 예소 / "8-5 기기 설정" (node-id 392:2304, "앱 초안 3" 프레임 안).
/// 기기 상세 관리 화면 우측 상단 설정 톱니바퀴를 누르면 도착한다.
///
/// 닉네임은 "완료"를 누를 때 서버(`PATCH /devices/:id`)에 저장하고, "기기 삭제하기"는
/// 확인 후 `DELETE /devices/:id`로 연결을 해제한다. 메모와 "기기 백업하기"는 서버에
/// 대응하는 API가 없어서 아직 저장되지 않는다.
class DeviceSettingsScreen extends ConsumerStatefulWidget {
  const DeviceSettingsScreen({
    super.key,
    required this.deviceId,
    required this.deviceOwnerName,
  });

  final int deviceId;
  final String deviceOwnerName;

  @override
  ConsumerState<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends ConsumerState<DeviceSettingsScreen> {
  late final _nicknameController = TextEditingController(text: widget.deviceOwnerName);
  final _memoController = TextEditingController();
  bool _busy = false;

  /// 색 고르기 창에서 고른 팔레트 인덱스. 닉네임처럼 "완료"를 눌러야
  /// 저장되므로, 그 전까지는 이 화면에서만 미리 보여준다(null = 안 바꿈).
  int? _pickedColor;

  Future<void> _pickColor(int current) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _DeviceColorSheet(selected: current),
    );
    if (picked != null && mounted) setState(() => _pickedColor = picked);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기를 삭제할까요?'),
        content: Text('${widget.deviceOwnerName}의 기기 연결이 해제돼요.'),
        actions: [
          // 여기서는 go_router의 context.pop()이 아니라 Navigator.pop을
          // 직접 써야 한다 — showDialog는 다이얼로그를 go_router가 아니라
          // 루트 Navigator에 직접 올리기 때문에, go_router의 pop을 쓰면
          // 다이얼로그 대신 이 화면 자체가 닫혀버릴 수 있다.
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await ref.read(deviceActionsProvider).deleteDevice(widget.deviceId);
      if (mounted) context.go('/devices');
    });
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final renamed = nickname.isNotEmpty && nickname != widget.deviceOwnerName;
    final pickedColor = _pickedColor;
    if (!renamed && pickedColor == null) {
      context.pop();
      return;
    }
    await _run(() async {
      final actions = ref.read(deviceActionsProvider);
      if (pickedColor != null) await actions.setDeviceColor(widget.deviceId, pickedColor);
      if (renamed) await actions.renameDevice(widget.deviceId, nickname);
      if (mounted) context.pop();
    });
  }

  /// 서버 호출 한 건을 돌리는 동안 버튼을 잠그고, 실패하면 서버 메시지를 보여 준다.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 홈/기기 관리 그리드와 같은 색(고른 색 또는 등록 순번 색)에서 시작하고,
    // 색 고르기 창에서 바꾸면 저장 전에도 바로 바뀐 색으로 보여준다.
    final colorIndex = _pickedColor ??
        ref.watch(deviceColorIndexProvider(widget.deviceId)) % kDeviceIconAssets.length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    '기기 설정',
                    style: TextStyle(
                      color: kDeviceOverviewLabelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Figma 8-5: 기기 75x101 + 오른쪽 아래 "+" 배지(27, 테두리 포함 33).
                  // 기기나 배지를 누르면 색 고르기 창이 열린다.
                  GestureDetector(
                    onTap: () => _pickColor(colorIndex),
                    child: SizedBox(
                      width: 85,
                      height: 113,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DeviceAvatar(deviceIconAssetFor(colorIndex), width: 75, height: 101),
                          const Positioned(
                            left: 52,
                            top: 80,
                            width: 33,
                            height: 33,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AssetIcon('assets/images/device_color_badge_bg.svg'),
                                SizedBox(
                                  width: 16.66,
                                  height: 16.66,
                                  child: AssetIcon('assets/images/device_color_badge_plus.svg'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '닉네임',
                          style: TextStyle(color: kDeviceOverviewLabelColor, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _nicknameController,
                            style: const TextStyle(color: kDeviceOverviewLabelColor, fontSize: 14),
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('메모', style: TextStyle(color: kDeviceOverviewLabelColor, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: TextField(
                  controller: _memoController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: kDeviceOverviewLabelColor, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '메모하세요...',
                    hintStyle: TextStyle(color: kDeviceOverviewStatusColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SettingsRow(label: '기기 백업하기', onTap: () {}),
              const SizedBox(height: 10),
              _SettingsRow(
                label: '기기 삭제하기',
                danger: true,
                onTap: _busy ? () {} : _confirmDelete,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _busy ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDeviceOverviewBrandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('완료', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기기 색 고르기 창. Figma에 이 창의 디자인이 없어서 기기 관리 그리드
/// 카드와 같은 스타일(흰 바탕, 둥근 모서리)로 맞췄다. 색을 누르면 그
/// 팔레트 인덱스를 돌려주며 닫힌다.
class _DeviceColorSheet extends StatelessWidget {
  const _DeviceColorSheet({required this.selected});

  final int selected;

  static const _labels = ['연두', '흰색', '보라'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기기 색상',
              style: TextStyle(
                color: kDeviceOverviewLabelColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < kDeviceIconAssets.length; i++)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(i),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 108,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: i == selected
                                  ? kDeviceOverviewBrandBlue
                                  : const Color(0xFFE5E5E5),
                              width: i == selected ? 2 : 1,
                            ),
                          ),
                          child: DeviceAvatar(kDeviceIconAssets[i], width: 56, height: 75),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            color: kDeviceOverviewLabelColor,
                            fontSize: 13,
                            fontWeight: i == selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "기기 백업하기" / "기기 삭제하기" 한 줄. [danger]가 true면 삭제 행동
/// 처럼 빨간 배경 + 빨간 글씨로 그린다.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.onTap, this.danger = false});

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFE6E6) : Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: danger ? null : Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: danger ? const Color(0xFFE71A1A) : kDeviceOverviewLabelColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            RotatedBox(
              quarterTurns: 1,
              child: SvgPicture.asset(
                'assets/images/home_chevron_small.svg',
                width: 7,
                height: 4,
                colorFilter: danger
                    ? const ColorFilter.mode(Color(0xFFE71A1A), BlendMode.srcIn)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
