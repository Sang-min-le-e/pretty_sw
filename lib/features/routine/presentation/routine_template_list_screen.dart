import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/routine_template_providers.dart';
import '../domain/routine_template.dart';

/// Figma: 예소 / "템플릿 사용" (node-id 415:1847, "앱 초안 3" 프레임 안).
/// "루틴 추가 선택 화면"에서 "템플릿 사용"을 누르면 도착한다.
///
/// 저장된 템플릿(이름 + 하위 할 일 목록)을 목록으로 보여주고, 하나를
/// 고르면 "단일 루틴 추가하기" 폼으로 넘어가면서 이름/할 일 목록을 미리
/// 채워준다 — 시간/대상/날짜는 매번 다를 수 있어서 템플릿에는 담지 않고
/// 그 폼에서 새로 고른다.
class RoutineTemplateListScreen extends ConsumerWidget {
  const RoutineTemplateListScreen({super.key});

  static const _labelColor = Color(0xFF505050);
  static const _captionColor = Color(0xFF7F7F7F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(routineTemplateListProvider).value ?? const [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        bottom: false,
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
                  const Text(
                    '템플릿 사용',
                    style: TextStyle(color: _labelColor, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: templates.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          '저장된 템플릿이 없어요\n루틴을 추가할 때 "템플릿에 저장하기"를 켜면 여기에 모여요',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _captionColor, fontSize: 14, height: 1.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 19),
                      itemCount: templates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _TemplateCard(template: templates[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final RoutineTemplate template;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/routine/add/single', extra: template),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(23, 16, 15, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.title,
                    style: const TextStyle(
                      color: RoutineTemplateListScreen._labelColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    'assets/images/home_chevron_small.svg',
                    width: 7,
                    height: 4,
                  ),
                ),
              ],
            ),
            if (template.steps.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (var i = 0; i < template.steps.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12, left: 4),
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
                      Text(
                        template.steps[i],
                        style: const TextStyle(
                          color: RoutineTemplateListScreen._labelColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
