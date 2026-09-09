import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import 'widgets/device_overview.dart';

/// Figma: 예소 / 홈화면 (node-id 392:5304, "앱 초안 3" 프레임 안).
///
/// 로그인/온보딩을 마친 뒤 도착하는 홈 화면. 내 기기 상태, 연결된 기기
/// 카드, 현재 루틴 카드를 보여준다.
///
/// 상단 바(로고+벨) 아래 "OO의 기기" 제목부터 "현재 루틴" 카드까지는
/// 기기 상세 관리 화면(`DeviceDetailScreen`, node 405:6598)과 완전히
/// 똑같은 디자인이라 `widgets/device_overview.dart`에 공용 위젯으로
/// 빼뒀다 — 이 파일은 그 공용 위젯들을 어떤 순서로 배치할지와, 이 화면
/// 고유의 상단 바만 담당한다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFFF4F4F4); // 화면 배경(연회색)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // 화면 내용이 기기 높이보다 길어질 수 있어서(작은 화면 대비)
      // SingleChildScrollView로 감싸 세로 스크롤이 가능하게 했다.
      body: SingleChildScrollView(
        child: Column(
          // stretch: 자식 위젯들이 가로 폭을 화면 전체로 꽉 채우게 한다.
          // (흰색 상단 바가 화면 좌우 끝까지 닿아야 하기 때문)
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(), // 맨 위 흰 배경 바: 로고 + 알림 벨
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 24),
              child: Column(
                children: [
                  // "지예의 기기" 제목. "지예"는 지금 로그인한 계정과
                  // 연결된 첫 번째 자녀 이름을 하드코딩해둔 것이다(아직
                  // 여러 자녀를 전환하는 기능이 없다).
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 38),
                    child: DeviceTitleRow(deviceOwnerName: '지예'),
                  ),
                  const SizedBox(height: 4),
                  // 온라인 / 연결됨 / 배터리 상태 3줄
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 38),
                    child: DeviceStatusList(),
                  ),
                  const SizedBox(height: 20),
                  // 로봇 기기 아바타 + 좌우 이전/다음 화살표
                  const DeviceCarousel(),
                  const SizedBox(height: 48),
                  // "기기 상태" 소제목 + "3분전 동기화됨" 캡션
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: DeviceStatusHeaderRow(),
                  ),
                  const SizedBox(height: 12),
                  // "연결된 기기" 카드 + "현재 루틴" 카드, 세로로 나란히
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        ConnectedDevicesCard(
                          onTap: () => context.push('/connected-devices'),
                        ),
                        const SizedBox(height: 12),
                        const CurrentRoutineCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // 하단 탭바는 4개 화면(홈/루틴/기기/내 정보)이 공유하는 위젯이라
      // 별도 파일(app/widgets/bottom_nav_bar.dart)로 빼뒀다.
      // currentIndex: 0 은 "지금 홈 탭이 선택된 상태"라는 뜻으로, 홈 아이콘이
      // 파란색으로, 나머지는 회색으로 그려지게 한다.
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

/// 화면 맨 위, 흰 배경의 상단 바. Tomo 로고(좌) + 알림 벨(우).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // 상태 표시줄(시계·배터리 아이콘) 영역과 겹치지 않도록 SafeArea로
      // 감싼다. bottom: false 는 "아래쪽 안전 영역은 신경 안 써도 된다"는
      // 뜻(이 바는 화면 맨 위에 있으니까).
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(31, 16, 31, 16),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/home_logo.svg', height: 30),
              // Spacer: 남은 가로 공간을 전부 차지해서, 로고는 왼쪽 끝에
              // 알림 벨은 오른쪽 끝에 붙게 밀어준다.
              const Spacer(),
              const _NotificationBellButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 알림 벨 아이콘 + 우측 상단에 겹쳐진 빨간 알림 개수 뱃지("2").
/// 뱃지가 벨 아이콘 바깥으로 살짝 삐져나오게 그려야 해서 Stack + Positioned를
/// 쓴다(일반 Row/Column으로는 이렇게 "겹치는" 배치를 할 수 없다).
class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {}, // 알림 화면이 아직 없어서 지금은 반응 없음
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          // clipBehavior: Clip.none 을 줘야 Positioned로 벨 바깥까지
          // 나간 뱃지가 잘리지 않고 다 보인다(기본값은 자식이 부모
          // 영역 밖으로 나가면 잘라내 버림).
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              'assets/images/home_bell.svg',
              width: 22,
              height: 21,
            ),
            Positioned(
              // 벨 아이콘 기준 왼쪽 위로 살짝 벗어난 위치(음수 값)에
              // 뱃지를 겹쳐 그린다.
              top: -5,
              right: -6,
              child: Container(
                width: 13,
                height: 13,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE71A1A),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
