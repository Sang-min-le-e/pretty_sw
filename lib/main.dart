import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/storage/local_storage_service.dart';
import 'features/onboarding/data/onboarding_repository.dart';

void main() async {
  // Flutter 엔진과 위젯 바인딩이 준비되기 전에는 Hive 같은 플랫폼 채널을 쓰는
  // 코드를 실행할 수 없다. runApp() 전에 비동기 초기화를 하려면 항상 이 호출이
  // 먼저 있어야 한다 — 이 프로젝트에서 반복되는 "국룰" 같은 코드.
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // 달력/날짜 위젯에서 'ko_KR' 로케일을 쓰려면 intl 패키지의 한국어 날짜 심볼
  // (월/요일 이름 등)을 미리 로드해둬야 한다. 이걸 빼먹으면 앱이 아니라
  // 실행 중에 LocaleDataException이 던져진다.
  await initializeDateFormatting('ko_KR', null);

  // 온보딩을 이미 끝낸 사용자인지를 라우터를 만들기 "전"에 미리 확인한다.
  // (go_router의 redirect 콜백으로 비동기 체크를 하는 방법도 있지만, 그러면
  // "일단 로그인 화면을 잠깐 보여줬다가 대시보드로 튕기는" 깜빡임이 생길 수 있다.
  // 처음부터 올바른 시작 화면을 정해서 라우터를 만드는 쪽이 더 간단하고 확실하다.)
  final onboardingRepository = OnboardingRepository(LocalStorageService());
  final isOnboardingComplete = await onboardingRepository.isComplete();
  final initialLocation = isOnboardingComplete ? '/' : '/onboarding/social-login';

  runApp(
    ProviderScope(
      child: RoutineApp(router: buildAppRouter(initialLocation: initialLocation)),
    ),
  );
}
