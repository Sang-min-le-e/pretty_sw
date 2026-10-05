import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../../app/widgets/progress_ring.dart';
import '../../home/presentation/widgets/device_overview.dart';
import '../../children/data/child_providers.dart';
import '../../routine/data/routine_providers.dart';
import '../../routine/domain/routine.dart';

/// Figma: 예소 / "8-2 한달 통계" · "8-3 일주일 통계" · "8-4 하루 성취도"
/// (node-id 392:2382 / 392:2499 / 392:2321, "앱 초안 3" 프레임 안).
///
/// 세 화면 모두 레이아웃(진행률 원 + 완료/미완료 루틴 목록)이 완전히
/// 같고 "어떤 기간을 볼지"만 다르다 — Figma에서는 진행률 카드의 좌우
/// 화살표를 누르거나 옆으로 쓸어 넘겨서 하루→일주일→한달 순서로 넘어가는
/// 세 개의 화면이지만, 여기서는 하나의 화면 안에서 [_Period] 상태만
/// 바꾸는 방식으로 구현했다 — 화면을 3벌 복사하지 않아도 되고, 좌우
/// 화살표를 누르면 그 자리에서 바로 다시 그려진다.
///
/// Figma 목업의 "667/1000"(한달) 같은 숫자는 만보기 등 이 앱에 없는
/// 센서 데이터로 보여서, 대신 세 기간 모두 "완료한 할 일 수 / 전체 할 일
/// 수"로 통일했다 — 서버에서 받은 루틴(`calendar`)의 할 일 상태로 계산할 수
/// 있는 값이라 이 쪽이 더 정직하다. 보여주는 데이터는 지금 선택한 자녀의
/// 것이다(기기가 아직 자녀와 연결돼 있지 않아서 [deviceOwnerName]은 제목에만
/// 쓴다).
class DeviceStatsScreen extends ConsumerStatefulWidget {
  const DeviceStatsScreen({super.key, required this.deviceOwnerName});

  final String deviceOwnerName;

  @override
  ConsumerState<DeviceStatsScreen> createState() => _DeviceStatsScreenState();
}

enum _Period { day, week, month }

extension on _Period {
  String get label => switch (this) {
    _Period.day => '하루 성취도',
    _Period.week => '일주일 통계',
    _Period.month => '한달 통계',
  };

  _Period get prev => switch (this) {
    _Period.day => _Period.month,
    _Period.week => _Period.day,
    _Period.month => _Period.week,
  };

  _Period get next => switch (this) {
    _Period.day => _Period.week,
    _Period.week => _Period.month,
    _Period.month => _Period.day,
  };
}

class _DeviceStatsScreenState extends ConsumerState<DeviceStatsScreen> {
  _Period _period = _Period.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final range = _rangeFor(today, _period);
    // 지금 선택한 자녀의 이 기간 루틴을 서버에서 받는다(자녀가 아직 없으면 빈 목록).
    final child = ref.watch(currentChildProvider);
    final periodRoutines = child == null
        ? <Routine>[]
        : (ref
                  .watch(
                    routineCalendarProvider((
                      childId: child.childId,
                      from: range.from,
                      to: range.to,
                    )),
                  )
                  .value ??
              const <Routine>[])
              .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    final totalSteps = periodRoutines.fold<int>(0, (sum, r) => sum + r.totalCount);
    final completedSteps = periodRoutines.fold<int>(0, (sum, r) => sum + r.doneCount);
    final ratio = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    final percent = (ratio * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: _StatsTopBar(onBack: () => context.pop()),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 19),
                  child: Row(
                    children: [
                      _PeriodArrow(
                        pointsLeft: true,
                        onTap: () => setState(() => _period = _period.prev),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.deviceOwnerName}의 ${_period.label}',
                              style: const TextStyle(
                                color: kDeviceOverviewLabelColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ProgressRing(
                              ratio: ratio,
                              diameter: 170,
                              center: Text(
                                '$percent%',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$completedSteps/$totalSteps',
                              style: const TextStyle(
                                color: Color(0xFF868686),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _PeriodArrow(
                        pointsLeft: false,
                        onTap: () => setState(() => _period = _period.next),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 37),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '루틴',
                      style: TextStyle(color: kDeviceOverviewLabelColor, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    if (periodRoutines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '이 기간에 등록된 루틴이 없어요',
                          style: TextStyle(color: kDeviceOverviewCaptionColor, fontSize: 13),
                        ),
                      )
                    else
                      for (final routine in periodRoutines) ...[
                        _StatRoutineRow(routine: routine),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  /// [period]에 해당하는 조회 기간(둘 다 날짜만 의미). 서버의 `calendar`가 한 번에
  /// 한 달 안쪽의 범위를 주므로 하루·일주일(일요일 시작)·이번 달로 자른다.
  static ({DateTime from, DateTime to}) _rangeFor(DateTime today, _Period period) {
    final day = DateTime(today.year, today.month, today.day);
    switch (period) {
      case _Period.day:
        return (from: day, to: day);
      case _Period.week:
        // 오늘이 속한 주(일요일 시작)의 시작/끝 날짜를 구한다.
        final start = day.subtract(Duration(days: day.weekday % 7));
        return (from: start, to: start.add(const Duration(days: 6)));
      case _Period.month:
        return (from: DateTime(day.year, day.month, 1), to: DateTime(day.year, day.month + 1, 0));
    }
  }
}

class _StatsTopBar extends StatelessWidget {
  const _StatsTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkResponse(
          onTap: onBack,
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
          '상세 기기 관리',
          style: TextStyle(
            color: kDeviceOverviewLabelColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        InkResponse(
          onTap: () {},
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

/// 진행률 카드 좌우의 "이전/다음 기간" 화살표.
class _PeriodArrow extends StatelessWidget {
  const _PeriodArrow({required this.pointsLeft, required this.onTap});

  final bool pointsLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: RotatedBox(
          quarterTurns: pointsLeft ? 3 : 1,
          child: SvgPicture.asset(
            'assets/images/home_chevron_prev.svg',
            width: 14,
            height: 8,
            colorFilter: const ColorFilter.mode(
              Color(0xFFCACACA),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

/// 통계 화면의 루틴 한 줄. 할 일을 전부 끝냈으면 파란 배경(흰 글씨),
/// 아니면 흰 배경(진한 글씨)으로 완료 여부를 색으로 바로 알아볼 수 있게
/// 한다 — 목록 화면의 `RoutineCard`와 달리 이 화면만의 색 규칙이라 별도
/// 위젯으로 뒀다.
class _StatRoutineRow extends StatelessWidget {
  const _StatRoutineRow({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final allCompleted = routine.totalCount > 0 && routine.doneCount == routine.totalCount;
    final timeLabel = routine.timeLabel;

    final titleColor = allCompleted ? Colors.white : kDeviceOverviewLabelColor;
    final captionColor = allCompleted ? Colors.white.withValues(alpha: 0.8) : kDeviceOverviewCaptionColor;

    return GestureDetector(
      onTap: () => context.push('/routine/detail/${routine.id}', extra: routine),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(23, 14, 15, 14),
        decoration: BoxDecoration(
          color: allCompleted ? kDeviceOverviewBrandBlue : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${timeLabel.isEmpty ? '' : '$timeLabel '}${routine.title}',
                    style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '・${routine.date.month}/${routine.date.day}',
                    style: TextStyle(color: captionColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${routine.doneCount}/${routine.totalCount}',
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
