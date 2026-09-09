import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../data/routine_providers.dart';
import 'widgets/add_routine_button.dart';
import 'widgets/routine_card.dart';

/// Figma: 예소 / "1. 일정 탭 첫 화면" (node-id 392:1740, "앱 초안 3" 프레임 안).
///
/// 하단 탭바의 "루틴" 탭이자, 홈 화면의 "현재 루틴" 카드를 눌렀을 때
/// 도착하는 화면이기도 하다. 진짜 달력(월 이동 가능) + 선택한 날짜의
/// 루틴 카드 목록 + 오른쪽 아래 루틴 추가 버튼(+)으로 이루어진다.
///
/// 카드 목록은 하드코딩된 예시 데이터가 아니라 Hive에 저장된 루틴들을
/// [routinesForDateProvider]로 걸러서 보여준다. 지금은 "+" 버튼을 눌러도
/// 아무 일도 일어나지 않는데(추가 화면은 나중에 붙일 예정), 그 말은 곧
/// 루틴을 하나도 추가하지 않은 상태(=빈 화면)가 현재 이 화면의 정상적인
/// 초기 상태라는 뜻이다.
///
/// Figma에서 "2. 오늘 할 일" 화면(node 286:5271)은 이름 자체가 "1번
/// 화면 하단 스크롤 시 표시"라서, 목록 맨 아래를 넘어 더 당기면(overscroll)
/// [TodayRoutinesScreen]으로 넘어가도록 만들었다 — 그 화면에서 위쪽
/// 화살표를 누르거나 맨 위에서 위로 더 당기면 다시 이 화면으로 돌아온다.
class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  static const _bg = Color(0xFFF4F4F4);

  /// 지금 달력에 펼쳐 보여주고 있는 "월"(day는 항상 1로 고정해 둔다).
  late DateTime _displayedMonth;

  /// 사용자가 달력에서 콕 찍어 선택한 날짜. 이 날짜의 루틴만 아래
  /// 목록에 나온다.
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // 화면을 처음 열면 "오늘"이 선택된 상태로 시작한다.
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _displayedMonth = DateTime(today.year, today.month);
  }

  /// 달력 칸을 눌러 날짜를 바꿀 때 호출. 다른 달의 칸을 눌렀다면(예:
  /// 이전/다음 달로 넘어간 뒤 그 달의 날짜를 고르는 경우) 보여주는 달도
  /// 함께 그 날짜의 달로 맞춘다.
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  /// 좌우 화살표로 달을 넘긴다. [delta]는 -1(이전 달) 또는 +1(다음 달).
  void _shiftMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
    });
  }

  /// 맨 아래를 넘어 얼마나 더 당겼는지(px)가 이 값을 넘으면 "오늘 할 일"
  /// 화면으로 넘어간다. 너무 작으면 살짝만 당겨도 넘어가 버려서 실수로
  /// 넘어가기 쉽고, 너무 크면 잘 반응하지 않는 것처럼 느껴진다.
  static const _overscrollTriggerDistance = 60.0;

  /// "오늘 할 일" 화면으로 이미 넘어가는 중인지 표시하는 플래그.
  ///
  /// 세우는 시점: `context.push()`를 호출하는 바로 그 순간 동기적으로
  /// 세운다 — 한 번의 드래그 안에서 [ScrollUpdateNotification]이 여러
  /// 번(짧은 시간에 연달아) 발생할 수 있는데, 플래그 없이 매번 임계값만
  /// 검사하면 그 드래그 하나로 push()가 여러 번 겹쳐 호출돼서 "오늘 할
  /// 일" 화면이 스택에 여러 겹 쌓이고(뒤로가기를 여러 번 눌러야 진짜
  /// 달력으로 돌아옴) 만다.
  ///
  /// 푸는 시점: `context.push()`가 돌려주는 `Future`가 완료될 때(=
  /// "오늘 할 일" 화면이 pop돼서 이 화면으로 돌아왔을 때) 푼다. 한때
  /// [ModalRoute.isCurrent]를 [build]에서 검사해 풀어보려 했는데, 화면이
  /// 다시 보이게 됐다고 해서 [build]가 항상 다시 호출된다는 보장이
  /// 없어서(로컬 상태가 안 바뀌면 프레임워크가 rebuild를 건너뛸 수
  /// 있다) 한 번 돌아온 뒤엔 다시 당겨도 반응하지 않는 버그로 이어졌다.
  /// push가 돌려주는 Future는 그 라우트가 실제로 스택에서 빠질 때
  /// 확실하게 완료되므로 훨씬 안정적이다.
  bool _navigatingToToday = false;

  /// 스크롤 목록에서 발생하는 알림을 살펴보다가, 맨 아래에 이미 닿은
  /// 상태에서 사용자가 더 아래로 당기는(overscroll) 순간을 잡아 "오늘
  /// 할 일" 화면으로 넘어간다.
  ///
  /// `BouncingScrollPhysics`는(iOS 스타일로 살짝 튕기는 느낌을 주려고
  /// 일부러 골랐다) 끝을 넘어가는 드래그도 전부 [ScrollUpdateNotification]
  /// 으로만 보고하고 [OverscrollNotification]은 절대 보내지 않는다(그건
  /// 안드로이드 기본 물리인 `ClampingScrollPhysics`가 "더 못 움직였다"는
  /// 뜻으로 보낼 때만 쓰는 알림이다). 그래서 `notification.metrics.pixels`가
  /// `maxScrollExtent`를 얼마나 넘었는지를 직접 계산해서 판단해야 한다.
  /// `false`를 돌려줘야 이 알림이 위쪽(예: 스크롤바 등)으로도 계속
  /// 전달된다.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && !_navigatingToToday) {
      final metrics = notification.metrics;
      final overscrolledPastBottom = metrics.pixels - metrics.maxScrollExtent;
      if (overscrolledPastBottom > _overscrollTriggerDistance) {
        _navigatingToToday = true;
        context.push('/routine/today').then((_) {
          if (mounted) setState(() => _navigatingToToday = false);
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final routinesForSelectedDay = ref.watch(
      routinesForDateProvider(_selectedDate),
    );
    final countsForDisplayedMonth = ref.watch(
      routineCountsByDayProvider(_displayedMonth),
    );

    return Scaffold(
      backgroundColor: _bg,
      // Stack으로 "스크롤되는 본문"과 "화면에 고정된 + 버튼"을 겹친다.
      // + 버튼은 목록을 아무리 스크롤해도 항상 같은 자리(오른쪽 아래)에
      // 떠 있어야 하기 때문에 스크롤 영역 바깥에 둔다.
      body: Stack(
        children: [
          // Positioned.fill이 없으면 Stack이 스크롤 영역의 "내용 높이"에만
          // 맞춰 줄어드는데, 어떤 날짜는 카드가 하나도 없어서 내용이
          // 화면보다 짧을 수 있다 — 그럴 때 "+" 버튼(bottom: 24)이 화면
          // 맨 아래가 아니라 그 짧은 내용 바로 밑에 붙어버린다. fill로
          // 강제로 화면 전체 높이를 차지하게 만들어야 버튼이 항상 화면
          // 진짜 아래쪽에 고정된다.
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: SingleChildScrollView(
                  // 기본(Android) 스크롤 물리는 끝에서 그냥 멈춰버려서
                  // overscroll 알림 자체가 발생하지 않는다. "더 당기면
                  // 다음 화면"이라는 제스처가 동작하려면 당겼을 때 살짝
                  // 튕기는 BouncingScrollPhysics가 필요하다. 게다가 내용이
                  // 화면보다 짧아서 원래는 스크롤할 필요가 없을 때도(예:
                  // 루틴이 하나도 없는 빈 상태) 당기는 동작 자체는 항상
                  // 받아줘야 하므로 AlwaysScrollableScrollPhysics로
                  // 감싼다 — 이게 없으면 스크롤할 내용이 없는 날엔 아예
                  // 드래그 자체가 무시돼서 다음 화면으로 넘어갈 수 없다.
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                        child: _MonthHeader(
                          month: _displayedMonth,
                          onPrevMonth: () => _shiftMonth(-1),
                          onNextMonth: () => _shiftMonth(1),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _WeekdayHeaderRow(),
                      _CalendarGrid(
                        month: _displayedMonth,
                        selectedDate: _selectedDate,
                        routineCountsByDay: countsForDisplayedMonth,
                        onSelectDate: _selectDate,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(19, 0, 19, 120),
                        child: RoutineCardList(
                          routines: routinesForSelectedDay,
                        ),
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

/// "10월" 같은 큰 월 제목 + 좌우로 달을 넘기는 화살표 버튼 두 개.
///
/// Figma 디자인 자체에는 화살표가 그려져 있지 않지만("10월" 글자만
/// 있음), 실제 달력처럼 월을 넘길 수 있어야 한다는 요구사항 때문에
/// 제목 오른쪽에 화살표를 추가했다. 화살표 아이콘은 새로 만들지 않고
/// 홈 화면의 기기 캐러셀에서 쓰는 것과 같은 에셋을 재사용한다.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${month.month}월',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        _MonthArrowButton(rotateQuarterTurns: 3, onTap: onPrevMonth), // 이전(‹)
        const SizedBox(width: 4),
        _MonthArrowButton(rotateQuarterTurns: 1, onTap: onNextMonth), // 다음(›)
      ],
    );
  }
}

/// 월 이동 화살표 버튼 하나. 원본 아이콘이 위쪽(^)을 가리키는 모양이라,
/// [rotateQuarterTurns]로 왼쪽(3=반시계 90도) 또는 오른쪽(1=시계 90도)을
/// 가리키게 돌려서 쓴다 — 홈 화면 `_DeviceCarousel`과 동일한 방식.
class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.rotateQuarterTurns,
    required this.onTap,
  });

  final int rotateQuarterTurns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: RotatedBox(
          quarterTurns: rotateQuarterTurns,
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
    );
  }
}

/// 요일 헤더 한 줄("일 월 화 수 목 금 토"). 7칸 모두 같은 회색이고,
/// 일요일/토요일이라고 색이 다르지 않다(색 구분은 실제 날짜 숫자에서만
/// 한다) — Figma 디자인 값(#a3a3a3) 그대로.
class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in _labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// 진짜 달(month) 그리드를 그리는 위젯. [month]의 1일이 무슨 요일인지
/// 계산해서 그 앞을 빈 칸으로 채우고, 마지막 주도 7칸을 다 채우도록
/// 뒤쪽을 빈 칸으로 채워서 항상 "완전한 주" 단위로 줄을 맞춘다.
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selectedDate,
    required this.routineCountsByDay,
    required this.onSelectDate,
  });

  final DateTime month;
  final DateTime selectedDate;

  /// "이 달의 N일에는 루틴이 몇 개 있는지" 맵(없는 날은 키가 없음).
  final Map<int, int> routineCountsByDay;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    // Dart의 weekday는 월=1 ~ 일=7이라서, "일요일 시작" 달력 기준으로
    // 앞에 몇 칸을 비워야 하는지 구하려면 7로 나눈 나머지를 쓴다
    // (일요일이면 7 % 7 = 0칸, 월요일이면 1 % 7 = 1칸, ...).
    final leadingEmptyCells = firstWeekday % 7;

    final totalCells = leadingEmptyCells + daysInMonth;
    // 마지막 주도 7칸을 꽉 채우도록 뒤쪽 빈 칸 개수를 계산.
    final trailingEmptyCells = (7 - (totalCells % 7)) % 7;

    final today = DateTime.now();

    final cells = <Widget>[];
    for (var i = 0; i < leadingEmptyCells; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final column = (leadingEmptyCells + day - 1) % 7;
      cells.add(
        _CalendarDayCell(
          date: date,
          column: column,
          isToday:
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day,
          isSelected:
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day,
          routineCount: routineCountsByDay[day],
          onTap: () => onSelectDate(date),
        ),
      );
    }
    for (var i = 0; i < trailingEmptyCells; i++) {
      cells.add(const SizedBox.shrink());
    }

    // 7개씩 끊어서 한 주(Row)씩 세로로 쌓는다.
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          children: cells
              .sublist(i, i + 7)
              .map((cell) => Expanded(child: cell))
              .toList(),
        ),
      );
    }

    return Column(children: rows);
  }
}

/// 달력 칸 하나: 날짜 숫자(+ 선택됐다면 파란 원, 오늘이 아니어도 그날
/// 루틴이 있으면 그 아래 작은 회색 개수 배지)를 그린다.
class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.column,
    required this.isToday,
    required this.isSelected,
    required this.routineCount,
    required this.onTap,
  });

  final DateTime date;

  /// 0=일요일 ... 6=토요일. 요일별 숫자 색(일=빨강, 토=파랑)을 정하는 데 쓴다.
  final int column;
  final bool isToday;
  final bool isSelected;
  final int? routineCount;
  final VoidCallback onTap;

  static const _sundayColor = Color(0xFFE71A1A);
  static const _saturdayColor = Color(0xFF5596FF);
  static const _selectedFill = Color(0xFF4ABEFF);
  static const _badgeFill = Color(0xFFEAEAEA);

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (column == 0) {
      textColor = _sundayColor;
    } else if (column == 6) {
      textColor = _saturdayColor;
    } else {
      textColor = Colors.black;
    }

    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: isSelected
                  ? const BoxDecoration(
                      color: _selectedFill,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // 그날 루틴이 하나라도 있으면 작은 회색 원 안에 개수를 보여준다.
            if (routineCount != null && routineCount! > 0)
              Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _badgeFill,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$routineCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(height: 17),
          ],
        ),
      ),
    );
  }
}
