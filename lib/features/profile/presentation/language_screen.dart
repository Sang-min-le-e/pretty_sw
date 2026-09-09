import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/back_header.dart';

/// Figma: 예소 / "언어" (node-id 392:5475, "앱 초안 3" 프레임 안, 이름
/// 없는 "iPhone 17 - 79" 프레임으로 저장돼 있었다). "내 정보" 화면의
/// "언어" 줄을 누르면 도착한다.
///
/// 실제로 앱 전체 문구를 다국어로 바꾸는 국제화(l10n)는 아직 붙어있지
/// 않아서(이 앱은 모든 화면이 한국어 문자열을 직접 쓴다), 골라도 화면
/// 안의 선택 표시만 바뀌고 실제 언어는 바뀌지 않는다.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = [
    '한국어',
    'English',
    '中文',
    '日本語',
    'Tiếng Việt',
    'العربية',
    'ภาษาไทย',
    'Español',
  ];

  String _selected = '한국어';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              BackHeader(title: '언어', onBack: () => context.pop()),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (final lang in _languages)
                      InkWell(
                        onTap: () => setState(() => _selected = lang),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Text(lang, style: const TextStyle(color: Color(0xFF505050), fontSize: 16)),
                              const Spacer(),
                              SvgPicture.asset(
                                _selected == lang
                                    ? 'assets/images/checkbox_filled.svg'
                                    : 'assets/images/checkbox_empty.svg',
                                width: 22,
                                height: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ABEFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('완료', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
