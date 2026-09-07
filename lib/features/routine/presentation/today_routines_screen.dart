import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../data/routine_providers.dart';
import 'widgets/add_routine_button.dart';
import 'widgets/routine_card.dart';

/// Figma: 예소 / "2. 오늘 할 일" (node-id 286:5271).
///
/// [RoutineScreen](달력 화면)의 목록 맨 아래를 더 당기면(overscroll)
/// 나타나는 화면 — 오늘 날짜의 루틴을 달력 없이 전체 목록으로 보여준다.
/// 위쪽 화살표를 누르거나, 목록 맨 위에서 위로 더 당기면(overscroll)
/// [RoutineScreen]으로 되돌아간다(그냥 `context.pop()`이라, 달력 화면이
/// 갖고 있던 선택 날짜/표시 월 상태는 그대로 남아있다).
///
/// 카드 디자인과 "+" 버튼은 달력 화면과 완전히 같은 위젯
/// (`RoutineCardList`, `AddRoutineButton`)을 그대로 재사용한다 — 두
/// 화면을 오갈 때 "+" 버튼이 같은 자리에 고정된 것처럼 보이게 하려면
/// 버튼 위치(`kAddRoutineButtonRight/Bottom`)도 반드시 같아야 한다.
class TodayRoutinesScreen extends ConsumerStatefulWidget {
  const TodayRoutinesScreen({super.key});

  @override
  ConsumerState<TodayRoutinesScreen> createState() =>
      _TodayRoutinesScreenState();
}

class _TodayRoutinesScreenState extends ConsumerState<TodayRoutinesScreen> {
  static const _bg = Color(0xFFF4F4F4);

  /// 맨 위를 넘어 얼마나 더 당겼는지(px)가 이 값을 넘으면 달력 화면으로
  /// 돌아간다. [RoutineScreen]의 아래쪽 트리거 거리와 같은 값을 쓴다.
  static const _overscrollTriggerDistance = 60.0;

  /// 화살표 버튼과 위로 당기는 제스처가 공유하는 "뒤로 가기" 동작.
  /// 이 화면 인스턴스가 존재하는 동안 딱 한 번만 pop해야 한다 — 화살표
  /// 탭과 위로 당기는 스크롤 알림이 거의 동시에 겹쳐 들어올 수 있는데,
  /// 그때 `context.pop()`을 두 번 부르면 두 번째 호출이 (이미 이 라우트가
  /// 없어지는 중이라) 엉뚱하게 씹히거나 스택이 꼬일 수 있어서 막아준다.
  bool _hasPoppedOnce = false;

  void _goBack() {
    if (_hasPoppedOnce) return;
    _hasPoppedOnce = true;
    context.pop();
  }

  /// [RoutineScreen]의 `_handleScrollNotification`과 대칭인 로직 —
  /// 거기서는 "맨 아래를 넘어가면" 다음 화면으로 넘어갔다면, 여기서는
  /// "맨 위를 넘어가면"(=위로 더 당기면) 이전 화면으로 돌아간다.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && !_hasPoppedOnce) {
      final metrics = notification.metrics;
      final overscrolledPastTop = metrics.minScrollExtent - metrics.pixels;
      if (overscrolledPastTop > _overscrollTriggerDistance) {
        _goBack();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final routines = ref.watch(routinesForDateProvider(todayDate));

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Positioned.fill이 없으면 Stack이 스크롤 영역의 "내용 높이"에만
          // 맞춰 줄어드는데, 루틴이 하나뿐이라 내용이 화면보다 짧을 땐
          // "+" 버튼(bottom: 24)이 화면 맨 아래가 아니라 그 짧은 내용
          // 바로 밑에 붙어버린다. fill로 강제로 화면 전체 높이를 차지하게
          // 만들어야 버튼이 항상 화면 진짜 아래쪽에 고정된다.
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: SingleChildScrollView(
                  // RoutineScreen과 마찬가지로, 맨 위를 넘어가는 당김도
                  // 감지하려면 항상 당길 수 있게(AlwaysScrollable) +
                  // 살짝 튕기는(Bouncing) 물리가 필요하다.
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                        child: _TodayHeader(onBack: _goBack),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 19),
                        child: RoutineCardList(routines: routines),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: kAddRoutineButtonRight,
            bottom: kAddRoutineButtonBottom,
            child: AddRoutineButton(),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

/// "^ 오늘 할 일" 제목 줄. 화살표를 누르면 달력 화면으로 돌아간다 — 위로
/// 당겨도 같은 곳으로 돌아가기 때문에, 화살표도 "위로 가면 된다"는 뜻으로
/// 위쪽을 가리키게 그렸다.
class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.onBack});

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
            // 원본 화살표 아이콘 자체가 이미 위쪽(^)을 가리키는 모양이라
            // 따로 돌릴 필요가 없다(왼쪽 화살표였을 때는 반시계 90도
            // 돌렸었다).
            child: SvgPicture.asset(
              'assets/images/home_chevron_prev.svg',
              width: 14,
              height: 8,
              colorFilter: const ColorFilter.mode(
                Color(0xFF505050),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '오늘 할 일',
          style: TextStyle(
            color: Color(0xFF505050),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
