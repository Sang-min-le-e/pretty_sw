import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../data/routine_providers.dart';
import '../data/routine_template_providers.dart';
import '../domain/new_routine.dart';
import '../domain/routine_template.dart';
import 'widgets/routine_form_widgets.dart';

/// Figma: 예소 / "5. 단일 루틴 추가하기" · "6. 복합 루틴 추가하기" (node-id
/// 392:2567 / 392:2977, "앱 초안 3" 프레임 안). "4. 루틴 추가 선택
/// 화면"에서 "단일 루틴 추가하기" 또는 "복합 루틴 추가하기"를 누르면
/// 도착한다 — 두 화면은 [compound] 플래그 하나만 다르고 나머지 폼(이름/
/// 시간/일반·기간·반복·다중 탭)은 완전히 같아서 화면 하나로 합쳤다.
/// "복합 루틴"일 때만 "행동 추가"(하위 할 일 목록)와 "템플릿에 저장하기"
/// 체크박스가 추가로 보인다. 템플릿은 서버에 자녀별로 저장된다.
///
/// 만든 루틴은 지금 보는 자녀(`currentChildProvider`)의 것으로 서버에
/// 저장된다(`POST /children/:childId/big-routines`). 네 탭은 서버의 반복
/// 모드(`repeatType`)에 이렇게 대응한다:
/// - 일반: 날짜 하나 → `RANGE`(시작일 = 종료일)
/// - 기간: 시작~끝 날짜 사이 매일 → `RANGE`
/// - 반복: 시작~끝 날짜 사이 선택한 요일마다 → `WEEKLY`(종료일 필수)
/// - 다중: 달력에서 찍은 날짜 여러 개 → `DATES`(최대 12개)
///
/// 날짜를 펼쳐서 날짜별 루틴을 만드는 일은 서버가 한다. 서버는 단일/복합을
/// 구분하지 않고 하위 할 일 개수로만 나뉘므로, 단일 루틴도 제목과 같은 이름의
/// 할 일 하나를 보낸다(완료 여부가 할 일에 붙기 때문).
///
/// (루틴 수정과 할 일 편집은 이 폼이 아니라 상세 화면의 톱니바퀴에서 여는
/// `RoutineEditScreen`·`RoutineStepsScreen`이 맡는다 — 서버가 수정에서는 날짜·
/// 반복을 못 바꿔서 화면을 따로 두었다.)
class AddRoutineScreen extends ConsumerStatefulWidget {
  const AddRoutineScreen({super.key, this.compound = false, this.template});

  final bool compound;

  /// "템플릿 사용" 화면에서 골라 들어온 경우, 그 템플릿의 이름/하위 할 일
  /// 목록을 폼에 미리 채워 넣는다.
  final RoutineTemplate? template;

  @override
  ConsumerState<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends ConsumerState<AddRoutineScreen> {
  static const _labelColor = Color(0xFF505050);
  static const _placeholderColor = Color(0xFFA3A3A3);
  static const _brandBlue = Color(0xFF4ABEFF);

  static const _tabs = ['일반', '기간', '반복', '다중'];
  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  /// [_weekdayLabels]와 같은 순서(0=일 … 6=토)인 서버의 요일 코드.
  static const _weekdayCodes = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  late final _titleController = TextEditingController(
    text: widget.template?.title ?? '',
  );
  final _stepInputController = TextEditingController();
  late List<String> _steps = List.of(widget.template?.steps ?? const []);

  // 템플릿으로 들어왔으면 그 템플릿의 시각으로 시작한다(없으면 00:00).
  late TimeOfDay _startTime = parseHhmm(widget.template?.startTime);
  late TimeOfDay _endTime = parseHhmm(widget.template?.endTime);
  String _activeTab = '일반';
  bool _saving = false;
  bool _saveAsTemplate = false;

  // 일반
  late DateTime _selectedDate;

  // 기간: 먼저 찍은 날짜가 시작, 그 다음 찍은(더 나중) 날짜가 끝.
  DateTime? _periodStart;
  DateTime? _periodEnd;

  // 다중
  final Set<DateTime> _multiDates = {};

  // 반복(매주): 서버의 WEEKLY는 시작일과 종료일이 모두 필요하다.
  final Set<int> _repeatWeekdays = {};
  late DateTime _repeatStart;
  late DateTime _repeatEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDate = today;
    _repeatStart = today;
    _repeatEnd = today.add(const Duration(days: 28)); // 기본 4주
  }

  @override
  void dispose() {
    _titleController.dispose();
    _stepInputController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _addStep() {
    final text = _stepInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps = [..._steps, text];
      _stepInputController.clear();
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps = [..._steps]..removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 폼 값을 서버 요청으로 바꾼다. 선택한 탭에서 아직 덜 정해진 값이 있으면
  /// 이유를 스낵바로 알리고 `null`을 돌려준다.
  NewRoutine? _toRequest(String title) {
    // 단일 루틴(또는 할 일을 안 적은 복합 루틴)은 제목과 같은 할 일 하나를 보낸다.
    final steps = _steps.isEmpty ? [title] : _steps;
    NewRoutine build({
      required RepeatType type,
      DateTime? start,
      DateTime? end,
      List<String> days = const [],
      List<DateTime> dates = const [],
    }) {
      return NewRoutine(
        title: title,
        startTime: formatHhmm(_startTime),
        endTime: formatHhmm(_endTime),
        repeatType: type,
        startDate: start,
        endDate: end,
        repeatDays: days,
        repeatDates: dates,
        steps: steps,
      );
    }

    switch (_activeTab) {
      case '기간':
        if (_periodStart == null || _periodEnd == null) {
          _showMessage('시작일과 종료일을 모두 골라 주세요');
          return null;
        }
        return build(type: RepeatType.range, start: _periodStart, end: _periodEnd);
      case '반복':
        if (_repeatWeekdays.isEmpty) {
          _showMessage('반복할 요일을 하나 이상 골라 주세요');
          return null;
        }
        final days = (_repeatWeekdays.toList()..sort())
            .map((i) => _weekdayCodes[i])
            .toList();
        return build(
          type: RepeatType.weekly,
          start: _repeatStart,
          end: _repeatEnd,
          days: days,
        );
      case '다중':
        if (_multiDates.isEmpty) {
          _showMessage('날짜를 하나 이상 골라 주세요');
          return null;
        }
        return build(
          type: RepeatType.dates,
          dates: _multiDates.toList()..sort(),
        );
      default: // '일반': 하루짜리는 RANGE에 시작일과 종료일을 같게.
        return build(type: RepeatType.range, start: _selectedDate, end: _selectedDate);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('루틴 이름을 입력해 주세요');
      return;
    }
    // 서버도 검사하지만(ROUTINE_INVALID_TIME_RANGE) 미리 알려서 왕복을 줄인다.
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      _showMessage('종료 시간은 시작 시간보다 뒤여야 해요');
      return;
    }
    final request = _toRequest(title);
    if (request == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(routineActionsProvider).createRoutine(request);

      // 템플릿 저장은 루틴을 만든 뒤에 한다. 실패해도 루틴은 이미 만들어졌으므로
      // 화면에 남아 다시 누르게 하면 같은 루틴이 또 생긴다 — 오류는 알림만 하고
      // 달력으로 넘어간다.
      String? templateError;
      if (widget.compound && _saveAsTemplate) {
        try {
          await ref.read(routineTemplateActionsProvider).addTemplate(
                title: title,
                startTime: formatHhmm(_startTime),
                endTime: formatHhmm(_endTime),
                steps: _steps,
              );
        } on ApiException catch (e) {
          templateError = e.message;
        }
      }

      if (!mounted) return;
      // "완료" = 저장하고 달력 화면으로 돌아간다. 선택 화면(4)까지 스택에
      // 두 겹 쌓여 있는 상태라 pop 대신 go로 곧장 '/routine'으로 보낸다.
      if (templateError != null) {
        _showMessage('루틴은 만들었지만 템플릿은 저장하지 못했어요: $templateError');
      }
      context.go('/routine');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: Row(
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
                            colorFilter: const ColorFilter.mode(_labelColor, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _titleForMode(),
                      style: const TextStyle(
                        color: _labelColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 37),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('루틴 이름', style: TextStyle(color: _labelColor, fontSize: 15)),
                    const SizedBox(height: 10),
                    PillField(
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(color: _labelColor, fontSize: 16),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '입력하세요....',
                          hintStyle: TextStyle(color: _placeholderColor, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('시간 설정', style: TextStyle(color: _labelColor, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TimeField(
                            time: _startTime,
                            suffix: '부터',
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TimeField(
                            time: _endTime,
                            suffix: '까지',
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    if (widget.compound) ...[
                      const SizedBox(height: 22),
                      const Text('행동 추가', style: TextStyle(color: _labelColor, fontSize: 15)),
                      const SizedBox(height: 10),
                      PillField(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _stepInputController,
                                style: const TextStyle(color: _labelColor, fontSize: 16),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '입력하세요....',
                                  hintStyle: TextStyle(color: _placeholderColor, fontSize: 16),
                                ),
                                onSubmitted: (_) => _addStep(),
                              ),
                            ),
                            InkResponse(
                              onTap: _addStep,
                              radius: 16,
                              child: const Icon(Icons.add, color: _brandBlue),
                            ),
                          ],
                        ),
                      ),
                      if (_steps.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (var i = 0; i < _steps.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 13,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9D9D9),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_steps[i], style: const TextStyle(color: _labelColor, fontSize: 15)),
                                ),
                                InkResponse(
                                  onTap: () => _removeStep(i),
                                  radius: 14,
                                  child: const Icon(Icons.close, size: 16, color: _placeholderColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final tab in _tabs) ...[
                            if (tab != _tabs.first) const SizedBox(width: 6),
                            Expanded(
                              child: _TabChip(
                                label: tab,
                                active: tab == _activeTab,
                                onTap: () => setState(() => _activeTab = tab),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      switch (_activeTab) {
                        '일반' => _MonthCalendar(
                          isSelected: (d) => _isSameDay(d, _selectedDate),
                          onSelectDate: (d) => setState(() => _selectedDate = d),
                        ),
                        '기간' => _MonthCalendar(
                          isSelected: (d) => _isInPeriod(d),
                          onSelectDate: _onPeriodDateTap,
                        ),
                        '다중' => _MonthCalendar(
                          isSelected: (d) => _multiDates.any((m) => _isSameDay(m, d)),
                          onSelectDate: _onMultiDateTap,
                        ),
                        _ => _RepeatSettings(
                          weekdayLabels: _weekdayLabels,
                          selectedWeekdays: _repeatWeekdays,
                          onToggleWeekday: (i) => setState(
                            () => _repeatWeekdays.contains(i)
                                ? _repeatWeekdays.remove(i)
                                : _repeatWeekdays.add(i),
                          ),
                          start: _repeatStart,
                          onStartChanged: (d) => setState(() {
                            _repeatStart = d;
                            // 종료일이 새 시작일보다 앞서면 4주 뒤로 다시 잡는다.
                            if (_repeatEnd.isBefore(d)) {
                              _repeatEnd = d.add(const Duration(days: 28));
                            }
                          }),
                          end: _repeatEnd,
                          onEndChanged: (d) => setState(() => _repeatEnd = d),
                        ),
                      },
                    ],
                  ),
                ),
              ),
              if (widget.compound) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 37),
                  child: InkWell(
                    onTap: () => setState(() => _saveAsTemplate = !_saveAsTemplate),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          _saveAsTemplate
                              ? 'assets/images/checkbox_filled.svg'
                              : 'assets/images/checkbox_empty.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '템플릿에 저장하기',
                          style: TextStyle(color: _labelColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 49),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('완료', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForMode() => widget.compound ? '복합 루틴 추가하기' : '단일 루틴 추가하기';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInPeriod(DateTime date) {
    if (_periodStart == null) return false;
    if (_periodEnd == null) return _isSameDay(date, _periodStart!);
    return !date.isBefore(_periodStart!) && !date.isAfter(_periodEnd!);
  }

  /// "기간" 탭: 첫 탭은 시작일로, 그보다 나중 날짜를 또 탭하면 끝일로
  /// 잡는다. 시작일보다 이른 날짜를 탭하면 새로 시작일부터 다시 잡는다.
  void _onPeriodDateTap(DateTime date) {
    setState(() {
      if (_periodStart == null || _periodEnd != null) {
        _periodStart = date;
        _periodEnd = null;
      } else if (date.isBefore(_periodStart!)) {
        _periodStart = date;
      } else {
        _periodEnd = date;
      }
    });
  }

  /// "다중" 탭: 이미 찍은 날짜면 빼고, 아니면 추가한다. 서버가 `DATES`로 받는
  /// 날짜는 최대 12개라서 13번째는 막고 이유를 알려준다.
  void _onMultiDateTap(DateTime date) {
    final existing = _multiDates.where((m) => _isSameDay(m, date)).firstOrNull;
    if (existing == null && _multiDates.length >= maxRepeatDates) {
      _showMessage('날짜는 최대 $maxRepeatDates개까지 고를 수 있어요');
      return;
    }
    setState(() {
      if (existing != null) {
        _multiDates.remove(existing);
      } else {
        _multiDates.add(date);
      }
    });
  }
}

/// "일반/기간/반복/다중" 탭 버튼 하나. 활성 탭만 파란 배경 + 흰 글씨.
class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(44),
      child: Container(
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _AddRoutineScreenState._brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(44),
          boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4)],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF989898),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// "일반/기간/다중" 탭이 공유하는 달력. 무엇을 선택된 것으로 볼지
/// ([isSelected])와 날짜를 탭했을 때 할 일([onSelectDate])을 부모가
/// 정해줘서, 하나의 달력 그리드로 세 가지 선택 방식(단일/기간/다중)을
/// 전부 표현한다.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.isSelected, required this.onSelectDate});

  final bool Function(DateTime date) isSelected;
  final ValueChanged<DateTime> onSelectDate;

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];
  static const _sundayColor = Color(0xFFE71A1A);
  static const _saturdayColor = Color(0xFF5596FF);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmptyCells = DateTime(month.year, month.month, 1).weekday % 7;

    final cells = <Widget>[];
    for (var i = 0; i < leadingEmptyCells; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final column = (leadingEmptyCells + day - 1) % 7;
      final selected = isSelected(date);

      Color textColor;
      if (selected) {
        textColor = Colors.white;
      } else if (column == 0) {
        textColor = _sundayColor;
      } else if (column == 6) {
        textColor = _saturdayColor;
      } else {
        textColor = Colors.black;
      }

      cells.add(
        InkResponse(
          onTap: () => onSelectDate(date),
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              width: 29,
              height: 29,
              alignment: Alignment.center,
              decoration: selected
                  ? const BoxDecoration(color: _AddRoutineScreenState._brandBlue, shape: BoxShape.circle)
                  : null,
              child: Text('$day', style: TextStyle(color: textColor, fontSize: 15)),
            ),
          ),
        ),
      );
    }
    final trailingEmptyCells = (7 - (cells.length % 7)) % 7;
    for (var i = 0; i < trailingEmptyCells; i++) {
      cells.add(const SizedBox.shrink());
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          children: cells.sublist(i, i + 7).map((cell) => Expanded(child: Center(child: cell))).toList(),
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${month.month}월 ${month.year}',
            style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final label in _labels)
              Expanded(
                child: Center(
                  child: Text(label, style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 14)),
                ),
              ),
          ],
        ),
        ...rows,
      ],
    );
  }
}

/// "반복" 탭의 내용. 서버가 지원하는 "매주"만 남겼다: 반복할 요일을 고르고,
/// 그 아래 "시작 날짜"와 "종료 날짜"를 고른다(둘 다 필수 — 서버의 `WEEKLY`가
/// 기간이 있어야 날짜를 펼칠 수 있다). 선택한 요일이 기간 안에 하루도 없으면
/// 서버가 오류 없이 0개를 만든다.
class _RepeatSettings extends StatelessWidget {
  const _RepeatSettings({
    required this.weekdayLabels,
    required this.selectedWeekdays,
    required this.onToggleWeekday,
    required this.start,
    required this.onStartChanged,
    required this.end,
    required this.onEndChanged,
  });

  final List<String> weekdayLabels;
  final Set<int> selectedWeekdays;
  final ValueChanged<int> onToggleWeekday;

  final DateTime start;
  final ValueChanged<DateTime> onStartChanged;
  final DateTime end;
  final ValueChanged<DateTime> onEndChanged;

  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('반복 요일', style: TextStyle(color: _labelColor, fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < weekdayLabels.length; i++)
              _WeekdayDot(
                label: weekdayLabels[i],
                selected: selectedWeekdays.contains(i),
                onTap: () => onToggleWeekday(i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsRow(
          label: '시작 날짜',
          trailing: _DateButton(
            date: start,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime(start.year - 1),
                lastDate: DateTime(start.year + 5),
              );
              if (picked != null) onStartChanged(picked);
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsRow(
          label: '종료 날짜',
          trailing: _DateButton(
            date: end,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: end,
                firstDate: start,
                lastDate: DateTime(start.year + 5),
              );
              if (picked != null) onEndChanged(picked);
            },
          ),
        ),
      ],
    );
  }
}


class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _RepeatSettings._labelColor, fontSize: 14)),
        trailing,
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        '${date.year}년 ${date.month}월 ${date.day}일',
        style: const TextStyle(color: _RepeatSettings._labelColor, fontSize: 14),
      ),
    );
  }
}

/// "반복" - "매주" 탭의 요일 하나(원 모양, 선택되면 파란 배경).
class _WeekdayDot extends StatelessWidget {
  const _WeekdayDot({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? _AddRoutineScreenState._brandBlue : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _RepeatSettings._labelColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
