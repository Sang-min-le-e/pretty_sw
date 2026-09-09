import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../home/presentation/widgets/device_overview.dart';

/// Figma: 예소 / "8-5 기기 설정" (node-id 392:2304, "앱 초안 3" 프레임 안).
/// 기기 상세 관리 화면 우측 상단 설정 톱니바퀴를 누르면 도착한다.
///
/// 닉네임/메모는 지금 화면 안에서만 값이 바뀌고 저장되지 않는다 — 기기가
/// 아직 Hive에 저장되는 실제 데이터가 아니라 홈/기기 탭에 하드코딩된
/// 값이라(다른 팀의 기기 스펙 대기 중), 여기서 편집해도 반영할 데이터
/// 저장소가 없다. "기기 백업하기"도 같은 이유로 아직 자리만 잡아뒀다.
/// "기기 삭제하기"는 실제로 지울 데이터가 없어 확인 다이얼로그만 보여주고
/// 확인하면 기기 목록으로 돌아간다.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key, required this.deviceOwnerName});

  final String deviceOwnerName;

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  late final _nicknameController = TextEditingController(text: widget.deviceOwnerName);
  final _memoController = TextEditingController();

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
    if (confirmed == true && mounted) {
      context.go('/devices');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(
                    width: 70,
                    height: 70,
                    child: AssetIcon('assets/images/device_icon.svg'),
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
                onTap: _confirmDelete,
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
            ],
          ),
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
