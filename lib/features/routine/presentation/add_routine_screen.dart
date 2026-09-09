import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/routine_providers.dart';
import '../data/routine_template_providers.dart';
import '../domain/routine.dart';
import '../domain/routine_recurrence.dart';
import '../domain/routine_template.dart';

/// [AddRoutineScreen]을 "id로 찾은 기존 루틴을 수정 모드로 열기" 용도로
/// 감싸는 얇은 래퍼. 라우트 빌더는 riverpod의 `ref`를 바로 못 받기 때문에,
/// `routineByIdProvider`로 루틴을 찾아오는 이 [ConsumerWidget] 한 겹이
/// 필요하다 — id가 잘못됐거나 루틴이 지워졌으면 안내 문구만 보여준다.
class RoutineEditScreen extends ConsumerWidget {
  const RoutineEditScreen({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(routineByIdProvider(routineId));
    if (routine == null) {
      return const Scaffold(body: Center(child: Text('루틴을 찾을 수 없어요')));
    }
    return AddRoutineScreen(compound: routine.steps.isNotEmpty, editing: routine);
  }
}

/// Figma: 예소 / "5. 단일 루틴 추가하기" · "6. 복합 루틴 추가하기" (node-id
/// 392:2567 / 392:2977, "앱 초안 3" 프레임 안). "4. 루틴 추가 선택
/// 화면"에서 "단일 루틴 추가하기" 또는 "복합 루틴 추가하기"를 누르면
/// 도착한다 — 두 화면은 [compound] 플래그 하나만 다르고 나머지 폼(이름/
/// 시간/대상/일반·기간·반복·다중 탭)은 완전히 같아서 화면 하나로 합쳤다.
/// "복합 루틴"일 때만 "행동 추가"(하위 할 일 목록, [Routine.steps])와
/// "템플릿에 저장하기" 체크박스가 추가로 보인다.
///
/// "일반/기간/반복/다중" 네 탭은 전부 실제로 동작한다:
/// - 일반: 날짜 하나를 골라 그 날 한 번만 등록
/// - 기간: 시작~끝 날짜 사이 매일 등록
/// - 반복: 매주(요일 선택)/매월(며칠)/매년(몇 월 며칠)/주기(N일·주·개월마다)
/// - 다중: 달력에서 원하는 날짜를 여러 개 콕콕 찍어서 등록
///
/// 반복 규칙 자체를 저장하지 않고, "완료"를 누르는 시점에
/// [RoutineRecurrence]로 해당하는 모든 날짜를 미리 계산해서 그 개수만큼
/// [Routine]을 각각 저장한다 — 자세한 이유는 그 파일의 문서 주석 참고.
///
/// Figma: 예소 / "7. 단일 루틴 수정하기" · "7-1 복합 루틴 수정하기"
/// (node-id 392:2772 / 392:3191)도 이 화면을 그대로 재사용한다 — [editing]에
/// 기존 루틴을 넘기면 값들을 미리 채우고, 제목이 "수정하기"로 바뀌고,
/// "완료"를 누르면 새로 만들지 않고 그 루틴을 덮어쓴다(같은 id로 저장하면
/// Hive가 알아서 덮어쓴다). 수정할 땐 "기간/반복/다중"으로 바꿔서 여러
/// 개를 새로 만들면 원본 하나는 그대로 남아 데이터가 꼬이므로, 탭 자체를
/// 숨기고 "일반"(날짜 하나)만 고를 수 있게 한다.
class AddRoutineScreen extends ConsumerStatefulWidget {
  const AddRoutineScreen({super.key, this.compound = false, this.template, this.editing});

  final bool compound;

  /// "템플릿 사용" 화면에서 골라 들어온 경우, 그 템플릿의 이름/하위 할 일
  /// 목록을 폼에 미리 채워 넣는다.
  final RoutineTemplate? template;

  /// 기존 루틴을 수정하러 들어온 경우 그 루틴. null이면 "추가" 모드다.
  final Routine? editing;

  @override
  ConsumerState<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends ConsumerState<AddRoutineScreen> {
  static const _labelColor = Color(0xFF505050);
  static const _placeholderColor = Color(0xFFA3A3A3);
  static const _brandBlue = Color(0xFF4ABEFF);

  static const _allMembers = ['지예', '예담', '예소'];
  static const _tabs = ['일반', '기간', '반복', '다중'];
  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const _repeatUnits = ['매주', '매월', '매년', '주기'];
  static const _intervalUnits = ['일', '주', '개월'];

  late final _titleController = TextEditingController(
    text: widget.editing?.title ?? widget.template?.title ?? '',
  );
  final _stepInputController = TextEditingController();
  late List<String> _steps = List.of(
    widget.editing?.steps ?? widget.template?.steps ?? const [],
  );

  late TimeOfDay _startTime = widget.editing == null
      ? const TimeOfDay(hour: 0, minute: 0)
      : TimeOfDay.fromDateTime(widget.editing!.dateTime);
  TimeOfDay _endTime = const TimeOfDay(hour: 0, minute: 0);
  late final Set<String> _selectedMembers = widget.editing == null
      ? {'지예'}
      : widget.editing!.participants.map((p) => p.name).toSet();
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

  // 반복
  String _repeatUnit = '매주';
  final Set<int> _repeatWeekdays = {};
  int _repeatDayOfMonth = 1;
  int _repeatMonth = 1;
  int _repeatDay = 1;
  int _repeatIntervalValue = 1;
  String _repeatIntervalUnit = '일';
  late DateTime _repeatStart;
  DateTime? _repeatEnd;

  @override
  void initState() {
    super.initState();
    final editingDate = widget.editing?.dateTime;
    final today = editingDate ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    _selectedDate = todayDate;
    _repeatStart = todayDate;
    _repeatDayOfMonth = todayDate.day;
    _repeatMonth = todayDate.month;
    _repeatDay = todayDate.day;
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

  void _toggleMember(String member) {
    setState(() {
      if (_selectedMembers.contains(member)) {
        _selectedMembers.remove(member);
      } else {
        _selectedMembers.add(member);
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

  /// [_activeTab]에 따라 이 루틴이 실제로 등록될 날짜 목록을 계산한다.
  /// 비어 있으면(설정이 덜 됐으면) 저장할 수 없다는 뜻이다.
  ///
  /// 수정 모드([widget.editing] != null)에서는 탭 자체를 숨기고 항상
  /// "일반"(날짜 하나)로만 계산한다 — 클래스 문서 주석 참고.
  List<DateTime> _resolveOccurrenceDates() {
    if (widget.editing != null) return [_selectedDate];
    switch (_activeTab) {
      case '일반':
        return [_selectedDate];
      case '기간':
        if (_periodStart == null || _periodEnd == null) return [];
        final dates = <DateTime>[];
        var day = _periodStart!;
        while (!day.isAfter(_periodEnd!)) {
          dates.add(day);
          day = day.add(const Duration(days: 1));
        }
        return dates;
      case '다중':
        return _multiDates.toList();
      case '반복':
        switch (_repeatUnit) {
          case '매주':
            return RoutineRecurrence.weekly(
              start: _repeatStart,
              weekdays: _repeatWeekdays,
              end: _repeatEnd,
            );
          case '매월':
            return RoutineRecurrence.monthly(
              start: _repeatStart,
              dayOfMonth: _repeatDayOfMonth,
              end: _repeatEnd,
            );
          case '매년':
            return RoutineRecurrence.yearly(
              start: _repeatStart,
              month: _repeatMonth,
              day: _repeatDay,
              end: _repeatEnd,
            );
          case '주기':
            return RoutineRecurrence.interval(
              start: _repeatStart,
              everyN: _repeatIntervalValue,
              unit: _repeatIntervalUnit,
              end: _repeatEnd,
            );
        }
        return [];
    }
    return [];
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 이름을 입력해 주세요')),
      );
      return;
    }
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대상을 한 명 이상 선택해 주세요')),
      );
      return;
    }
    final dates = _resolveOccurrenceDates();
    if (dates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜를 설정해 주세요')),
      );
      return;
    }

    final allSelected = _selectedMembers.length == _allMembers.length;
    final tag = allSelected ? '공통' : '${_selectedMembers.join(', ')}님의 기기';
    final participantNames = allSelected ? _allMembers : _selectedMembers.toList();
    final baseId = DateTime.now().microsecondsSinceEpoch;
    // 수정 모드에서는 이미 완료 표시된 구성원의 완료 상태를 그대로 두고,
    // 새로 추가된 구성원만 미완료로 시작한다.
    final existingParticipants = {
      for (final p in widget.editing?.participants ?? const <RoutineParticipant>[]) p.name: p,
    };

    setState(() => _saving = true);
    final actions = ref.read(routineActionsProvider);
    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      await actions.addRoutine(
        Routine(
          id: widget.editing?.id ?? '$baseId-$i',
          title: title,
          dateTime: DateTime(date.year, date.month, date.day, _startTime.hour, _startTime.minute),
          tag: tag,
          steps: _steps,
          participants: [
            for (final name in participantNames)
              RoutineParticipant(
                name: name,
                completed: existingParticipants[name]?.completed ?? false,
              ),
          ],
        ),
      );
    }

    if (widget.compound && _saveAsTemplate) {
      await ref.read(routineTemplateActionsProvider).addTemplate(
        RoutineTemplate(id: '$baseId', title: title, steps: _steps),
      );
    }

    if (!mounted) return;
    // "완료" = 저장하고 달력 화면으로 돌아간다. 선택 화면(4)까지 스택에
    // 두 겹 쌓여 있는 상태라 pop 대신 go로 곧장 '/routine'으로 보낸다.
    context.go('/routine');
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
                    _PillField(
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
                          child: _TimeField(
                            time: _startTime,
                            suffix: '부터',
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeField(
                            time: _endTime,
                            suffix: '까지',
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text('대상 선택', style: TextStyle(color: _labelColor, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final member in _allMembers) ...[
                          if (member != _allMembers.first) const SizedBox(width: 5),
                          Expanded(
                            child: _MemberChip(
                              name: member,
                              selected: _selectedMembers.contains(member),
                              onTap: () => _toggleMember(member),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.compound) ...[
                      const SizedBox(height: 22),
                      const Text('행동 추가', style: TextStyle(color: _labelColor, fontSize: 15)),
                      const SizedBox(height: 10),
                      _PillField(
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
                      // 수정 모드에서는 탭을 숨기고 "일반"(날짜 하나)만
                      // 고르게 한다 — 클래스 문서 주석 참고.
                      if (widget.editing == null) ...[
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
                      ],
                      switch (widget.editing == null ? _activeTab : '일반') {
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
                          unit: _repeatUnit,
                          units: _repeatUnits,
                          onUnitChanged: (u) => setState(() => _repeatUnit = u),
                          weekdayLabels: _weekdayLabels,
                          selectedWeekdays: _repeatWeekdays,
                          onToggleWeekday: (i) => setState(
                            () => _repeatWeekdays.contains(i)
                                ? _repeatWeekdays.remove(i)
                                : _repeatWeekdays.add(i),
                          ),
                          dayOfMonth: _repeatDayOfMonth,
                          onDayOfMonthChanged: (v) => setState(() => _repeatDayOfMonth = v),
                          month: _repeatMonth,
                          onMonthChanged: (v) => setState(() => _repeatMonth = v),
                          day: _repeatDay,
                          onDayChanged: (v) => setState(() => _repeatDay = v),
                          intervalValue: _repeatIntervalValue,
                          onIntervalValueChanged: (v) => setState(() => _repeatIntervalValue = v),
                          intervalUnit: _repeatIntervalUnit,
                          intervalUnits: _intervalUnits,
                          onIntervalUnitChanged: (u) => setState(() => _repeatIntervalUnit = u),
                          start: _repeatStart,
                          onStartChanged: (d) => setState(() => _repeatStart = d),
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

  String _titleForMode() {
    final editing = widget.editing != null;
    if (widget.compound) return editing ? '복합 루틴 수정하기' : '복합 루틴 추가하기';
    return editing ? '단일 루틴 수정하기' : '단일 루틴 추가하기';
  }

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

  void _onMultiDateTap(DateTime date) {
    setState(() {
      final existing = _multiDates.where((m) => _isSameDay(m, date)).firstOrNull;
      if (existing != null) {
        _multiDates.remove(existing);
      } else {
        _multiDates.add(date);
      }
    });
  }
}

/// 흰 알약 모양(radius 21) + 옅은 그림자 입력 필드 껍데기. 텍스트필드와
/// 시간 선택 버튼이 똑같은 껍데기를 재사용한다.
class _PillField extends StatelessWidget {
  const _PillField({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(21), onTap: onTap, child: content);
  }
}

/// "00:00 부터" / "00:00 까지"처럼 시각 + 안내 글자가 함께 붙은 시간
/// 선택 버튼. 누르면 표준 [showTimePicker] 다이얼로그가 뜬다.
class _TimeField extends StatelessWidget {
  const _TimeField({required this.time, required this.suffix, required this.onTap});

  final TimeOfDay time;
  final String suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return _PillField(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _AddRoutineScreenState._labelColor, fontSize: 16)),
          Text(suffix, style: const TextStyle(color: _AddRoutineScreenState._placeholderColor, fontSize: 16)),
        ],
      ),
    );
  }
}

/// "대상 선택"의 구성원 한 명(체크박스 + 이름) 칩.
class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              selected ? 'assets/images/checkbox_filled.svg' : 'assets/images/checkbox_empty.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: const TextStyle(
                color: _AddRoutineScreenState._labelColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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

/// "반복" 탭의 내용. [unit]에 따라 매주(요일)/매월(며칠)/매년(몇 월
/// 며칠)/주기(N일·주·개월마다) 중 하나의 하위 설정을 보여주고, 그 아래
/// 공통으로 "시작 날짜"와 "종료 날짜"(비워두면 끝없이 반복 — 실제로는
/// [RoutineRecurrence]가 1년까지만 생성한다) 를 고른다.
class _RepeatSettings extends StatelessWidget {
  const _RepeatSettings({
    required this.unit,
    required this.units,
    required this.onUnitChanged,
    required this.weekdayLabels,
    required this.selectedWeekdays,
    required this.onToggleWeekday,
    required this.dayOfMonth,
    required this.onDayOfMonthChanged,
    required this.month,
    required this.onMonthChanged,
    required this.day,
    required this.onDayChanged,
    required this.intervalValue,
    required this.onIntervalValueChanged,
    required this.intervalUnit,
    required this.intervalUnits,
    required this.onIntervalUnitChanged,
    required this.start,
    required this.onStartChanged,
    required this.end,
    required this.onEndChanged,
  });

  final String unit;
  final List<String> units;
  final ValueChanged<String> onUnitChanged;

  final List<String> weekdayLabels;
  final Set<int> selectedWeekdays;
  final ValueChanged<int> onToggleWeekday;

  final int dayOfMonth;
  final ValueChanged<int> onDayOfMonthChanged;

  final int month;
  final ValueChanged<int> onMonthChanged;
  final int day;
  final ValueChanged<int> onDayChanged;

  final int intervalValue;
  final ValueChanged<int> onIntervalValueChanged;
  final String intervalUnit;
  final List<String> intervalUnits;
  final ValueChanged<String> onIntervalUnitChanged;

  final DateTime start;
  final ValueChanged<DateTime> onStartChanged;
  final DateTime? end;
  final ValueChanged<DateTime?> onEndChanged;

  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsRow(
          label: '반복 기간',
          trailing: _Dropdown<String>(
            value: unit,
            items: units,
            labelOf: (v) => v,
            onChanged: onUnitChanged,
          ),
        ),
        const SizedBox(height: 12),
        switch (unit) {
          '매주' => Wrap(
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
          '매월' => _SettingsRow(
            label: '매월 며칠',
            trailing: _Dropdown<int>(
              value: dayOfMonth,
              items: List.generate(31, (i) => i + 1),
              labelOf: (v) => '$v일',
              onChanged: onDayOfMonthChanged,
            ),
          ),
          '매년' => Row(
            children: [
              Expanded(
                child: _Dropdown<int>(
                  value: month,
                  items: List.generate(12, (i) => i + 1),
                  labelOf: (v) => '$v월',
                  onChanged: onMonthChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dropdown<int>(
                  value: day,
                  items: List.generate(31, (i) => i + 1),
                  labelOf: (v) => '$v일',
                  onChanged: onDayChanged,
                ),
              ),
            ],
          ),
          _ => Row(
            children: [
              Expanded(
                child: _Dropdown<int>(
                  value: intervalValue,
                  items: List.generate(30, (i) => i + 1),
                  labelOf: (v) => '$v',
                  onChanged: onIntervalValueChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dropdown<String>(
                  value: intervalUnit,
                  items: intervalUnits,
                  labelOf: (v) => '$v마다',
                  onChanged: onIntervalUnitChanged,
                ),
              ),
            ],
          ),
        },
        const SizedBox(height: 12),
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
            placeholder: '없음',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: end ?? start,
                firstDate: start,
                lastDate: DateTime(start.year + 5),
              );
              onEndChanged(picked);
            },
            onClear: end == null ? null : () => onEndChanged(null),
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

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: _RepeatSettings._labelColor, fontSize: 14),
      items: [
        for (final item in items) DropdownMenuItem(value: item, child: Text(labelOf(item))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap, this.placeholder, this.onClear});

  final DateTime? date;
  final VoidCallback onTap;
  final String? placeholder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? (placeholder ?? '선택')
        : '${date!.year}년 ${date!.month}월 ${date!.day}일';
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: _RepeatSettings._labelColor, fontSize: 14)),
          if (onClear != null)
            InkResponse(
              onTap: onClear,
              radius: 12,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 14, color: Color(0xFFA3A3A3)),
              ),
            ),
        ],
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
