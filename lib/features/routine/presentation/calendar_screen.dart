import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Figma 노트 "루틴등록 UX": "루틴등록 메인창: 캘린더 -> 캘린더 날짜 클릭 시
/// '루틴 등록' 창으로 이동".
///
/// `table_calendar` 패키지는 이 프로젝트에서 직접 만들지 않고 pub.dev에서
/// 가져다 쓴 외부 패키지다. 달력 UI(월 이동, 요일 배치, 오늘 표시 등)는
/// 잘 만들어진 라이브러리가 이미 많아서, 이런 "범용 UI 부품"까지 직접 만드는 건
/// 시간 대비 얻는 게 적다 — 우리가 집중해야 할 건 "이 앱만의 도메인 로직"
/// (빅루틴/스몰루틴, 이행률 계산 같은 것들)이다.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDay);
    context.push('/calendar/$dateKey/routines');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('루틴 달력')),
      body: TableCalendar(
        // table_calendar는 표시 가능한 날짜 범위를 반드시 지정해야 한다.
        // 과거 1년 ~ 미래 1년 정도면 루틴을 미리/지나서 등록하는 용도로 충분하다.
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        locale: 'ko_KR',
        // 이 앱의 접근성 테마(app/theme.dart)가 기본 글자 크기를 20sp로 키워뒀는데,
        // table_calendar의 요일 줄(일/월/화/수/목/금/토) 높이는 표준 크기 글자
        // 기준으로 고정돼 있어서 그대로 두면 받침(예: 월->워, 목->모)이 위아래로
        // 잘려 보인다. 요일 줄 높이를 넉넉하게 늘려서 글자가 안 잘리게 한다.
        daysOfWeekHeight: 32,
        // "2 weeks"/"Month" 같은 형식 전환 버튼은 table_calendar가 영어로만
        // 제공하고, 이 앱에서는 "날짜 하나를 골라 루틴을 등록"하는 게 목적이라
        // 주/월 보기 전환 자체가 필요 없다. 지적장애인 대상 UI는 화면에 있는
        // 버튼 수가 적을수록 좋다는 접근성 원칙에도 맞아서 아예 숨겼다.
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }
}
