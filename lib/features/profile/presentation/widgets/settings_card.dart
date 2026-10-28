import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "내 정보" 탭 전반(내 정보 메인/사용자 설정 등)에서 반복되는 흰 카드
/// 스타일: 굵은 소제목 + 그 아래 줄 목록. [title]이 없으면(예: "사용자
/// 설정" 화면의 보호자 정보 카드) 소제목 없이 줄만 보여준다.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
        ],
      ),
      // Figma(내 정보): 소제목은 카드 위에서 15, 소제목→첫 줄 17, 줄 간격 18.
      padding: const EdgeInsets.fromLTRB(23, 15, 23, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(color: _labelColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 17),
          ],
          for (var i = 0; i < children.length; i++) ...[
            if (i != 0) const SizedBox(height: 18),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 카드 안의 줄 하나: 라벨 + (선택) 오른쪽 값 텍스트 + (선택) 화살표.
/// [onTap]이 있으면 줄 전체를 누를 수 있다.
class SettingsChevronRow extends StatelessWidget {
  const SettingsChevronRow({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
    this.danger = false,
    this.onTap,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final bool danger;
  final VoidCallback? onTap;

  static const _labelColor = Color(0xFF505050);
  static const _dangerColor = Color(0xFFE71A1A);

  @override
  Widget build(BuildContext context) {
    final textColor = danger ? _dangerColor : _labelColor;
    final row = Row(
      children: [
        Text(label, style: TextStyle(color: textColor, fontSize: 16)),
        const Spacer(),
        if (value != null) ...[
          Text(value!, style: TextStyle(color: valueColor ?? const Color(0xFF7F7F7F), fontSize: 16)),
          const SizedBox(width: 8),
        ],
        RotatedBox(
          quarterTurns: 1,
          child: SvgPicture.asset(
            'assets/images/home_chevron_small.svg',
            width: 7,
            height: 4,
            colorFilter: danger ? const ColorFilter.mode(_dangerColor, BlendMode.srcIn) : null,
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    // HitTestBehavior.opaque가 없으면 GestureDetector는 실제로 칠해진
    // 자식(텍스트·아이콘)에만 반응해서, 라벨과 화살표 사이 빈 공간을 눌렀을
    // 때 무시된다 — 줄 전체(화살표 포함)를 어디든 누르면 반응하게 하려면
    // 이 옵션으로 Row가 차지하는 영역 전체를 히트 테스트 대상으로 넓혀야 한다.
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: row);
  }
}

/// 카드 안의 줄 하나: 라벨 + 오른쪽 토글 스위치("알림"/"다크모드" 등).
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const _labelColor = Color(0xFF505050);
  static const _brandBlue = Color(0xFF99B6FF);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: _labelColor, fontSize: 16)),
        const Spacer(),
        // Figma의 스위치는 테두리 없는 납작한 iOS 스타일이라 adaptive로
        // 그린다(iOS에서는 CupertinoSwitch).
        // 기본 크기(51x31)면 줄이 Figma(40 간격)보다 커져서 높이 24로 줄여 맞춘다.
        SizedBox(
          height: 24,
          child: FittedBox(
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: _brandBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

/// 카드 안의 줄 하나: 라벨 + 오른쪽 값 텍스트만(눌러도 반응 없음, 예:
/// "앱 버전").
class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  static const _labelColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: _labelColor, fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Color(0xFF7F7F7F), fontSize: 16)),
      ],
    );
  }
}
