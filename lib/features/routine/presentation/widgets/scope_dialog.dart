import 'package:flutter/material.dart';

import '../../domain/change_scope.dart';

/// "이 날짜만 / 같은 반복 전체" 중 어디까지 적용할지 묻는 팝업. 고른 [ChangeScope]를
/// 돌려주고, 취소하면(바깥을 누르거나 "취소") `null`이다.
///
/// 서버는 이 루틴이 반복에 속하는지 알려 주지 않아서, 하루짜리 루틴에도 이
/// 질문이 뜬다. [defaultScope]는 서버의 기본값(수정·추가는 같은 반복 전체,
/// 삭제는 그 날짜만)이고 "(권장)" 표시를 붙여 보여준다.
Future<ChangeScope?> showScopeDialog(
  BuildContext context, {
  required String title,
  required String description,
  required ChangeScope defaultScope,
}) {
  return showDialog<ChangeScope>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            description,
            style: const TextStyle(color: Color(0xFF7F7F7F), fontSize: 13, height: 1.5),
          ),
        ),
        for (final scope in ChangeScope.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(scope),
            child: Text(
              '${_label(scope)}${scope == defaultScope ? ' (권장)' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: Color(0xFF7F7F7F))),
        ),
      ],
    ),
  );
}

String _label(ChangeScope scope) => switch (scope) {
  ChangeScope.single => '이 날짜만',
  ChangeScope.series => '같은 반복 전체 (오늘 이후)',
};
