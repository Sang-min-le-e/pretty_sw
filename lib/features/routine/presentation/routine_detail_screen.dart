import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../../app/widgets/progress_ring.dart';
import '../data/routine_providers.dart';
import '../domain/routine.dart';

/// Figma: 예소 / "3. 단일루틴 상세보기" (node-id 392:2096, "앱 초안 3" 프레임
/// 안). "오늘 할 일" 목록에서 루틴 카드의 화살표(›)를 누르면 도착한다.
///
/// 루틴 하나를 수행하는 가족 구성원들의 완료 현황을 원형 진행률 +
/// 완료/미완료 아바타 목록으로 보여준다. 완료 인원이 많아서 아바타 목록이
/// 화면보다 길어질 수 있는 경우("3-1" 변형, node 392:2182)는 이 화면
/// 전체가 이미 [SingleChildScrollView]로 스크롤되기 때문에 따로 처리할
/// 필요가 없다 — 화면 안에서 스크롤해서 다 확인할 수 있다.
class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  static const _bg = Color(0xFFF4F4F4);
  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(routineByIdProvider(routineId));

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: routine == null
            // 잘못된 id로 들어왔거나(딥링크 등), 루틴이 그 사이 삭제된
            // 경우를 대비한 방어적 처리. 실제 사용 흐름에서는 항상 목록에
            // 있는 루틴을 눌러서 들어오기 때문에 거의 발생하지 않는다.
            ? const Center(child: Text('루틴을 찾을 수 없어요'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                      child: _DetailHeader(
                        onBack: () => context.pop(),
                        onEdit: () => context.push('/routine/edit/$routineId'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 19),
                      child: _ProgressCard(routine: routine),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 37),
                      child: _ParticipantSection(
                        label: '완료',
                        participants: routine.participants
                            .where((p) => p.completed)
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 37),
                      child: _ParticipantSection(
                        label: '미완료',
                        participants: routine.participants
                            .where((p) => !p.completed)
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

/// 뒤로가기 화살표 + "오늘 할 일" 제목 + 설정 톱니바퀴(이 루틴 수정 화면으로 이동).
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkResponse(
          onTap: onBack,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(8),
            // 원본 화살표(home_chevron_prev)는 위쪽(^)을 가리키는 모양이라,
            // 왼쪽(‹)을 가리키게 하려면 반시계 방향으로 90도 돌려야 한다 —
            // 루틴 화면의 월 이동 화살표와 같은 방식.
            child: RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                'assets/images/home_chevron_prev.svg',
                width: 14,
                height: 8,
                colorFilter: const ColorFilter.mode(
                  RoutineDetailScreen._labelColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '오늘 할 일',
          style: TextStyle(
            color: RoutineDetailScreen._labelColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // 기기 관리 화면들에 있는 것과 같은 설정 톱니바퀴. 여기서는 이
        // 루틴을 수정하는 화면으로 이동한다(Figma "7"/"7-1").
        InkResponse(
          onTap: onEdit,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SvgPicture.asset(
              'assets/images/home_gear.svg',
              width: 20,
              height: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// 흰 카드: 루틴 제목 + 원형 진행률(완료 인원 비율, 가운데 "N%") +
/// 아래쪽에 "완료 인원 수/전체 인원 수" 큰 숫자.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final total = routine.participants.length;
    final completed = routine.participants.where((p) => p.completed).length;
    final ratio = total == 0 ? 0.0 : completed / total;
    final percent = (ratio * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 19),
      child: Column(
        children: [
          Text(
            routine.title,
            style: const TextStyle(
              color: RoutineDetailScreen._labelColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          ProgressRing(
            ratio: ratio,
            center: Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 44,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$completed/$total',
            style: const TextStyle(
              color: Color(0xFF868686),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// "완료" 또는 "미완료" 섹션 하나: 소제목 + 그 상태에 해당하는 구성원들을
/// 가로로 나열한 아바타 목록. 아무도 없으면(예: 아직 완료자가 없음)
/// 섹션 자체를 그리지 않는다.
class _ParticipantSection extends StatelessWidget {
  const _ParticipantSection({required this.label, required this.participants});

  final String label;
  final List<RoutineParticipant> participants;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RoutineDetailScreen._labelColor,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final participant in participants)
              _ParticipantAvatar(name: participant.name),
          ],
        ),
      ],
    );
  }
}

/// 가족 구성원 한 명의 아바타 칩: 흰 카드 안에 그 사람 색으로 칠해진
/// 로봇 기기 아이콘 + 이름. 세 자녀(지예/예담/예소)는 Figma에서 색이
/// 미리 정해져 있어서(연두/회색/보라) [_colorFor]로 이름에 맞는 아이콘을
/// 고른다 — 그 외 이름은 기본 회색 아이콘으로 대체한다.
class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 48, height: 50, child: SvgPicture.asset(_assetFor(name))),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: RoutineDetailScreen._labelColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static String _assetFor(String name) {
    switch (name) {
      case '지예':
        return 'assets/images/member_device_green.svg';
      case '예담':
        return 'assets/images/member_device_gray.svg';
      case '예소':
        return 'assets/images/member_device_purple.svg';
      default:
        return 'assets/images/member_device_gray.svg';
    }
  }
}
