import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/widgets/bottom_nav_bar.dart';
import '../../routine/data/routine_providers.dart';

/// Figma: 예소 / 홈화면 (node-id 288:1853).
///
/// 로그인/온보딩을 마친 뒤 도착하는 홈 화면. 내 기기 상태, 위치·와이파이
/// 카드, 오늘의 루틴 카드를 보여준다.
///
/// 이 파일은 화면 하나를 통째로 하나의 클래스에 담지 않고, Figma 디자인의
/// 각 구역(상단 바 / 기기 상태 / 캐러셀 / 카드들)을 전부 별도의 작은
/// private 위젯(`_XxxWidget`)으로 쪼개놓았다. 그래서 build() 메서드는
/// "어떤 순서로 어떤 구역들을 배치할지"만 보여주는 목차 역할만 하고, 실제
/// 각 구역의 세부 구현은 파일 아래쪽에 있는 해당 클래스에서 찾아보면 된다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 화면 전체에서 반복해서 쓰는 색상들을 한 곳에 모아둔 상수.
  // Dart에서는 static const는 "라이브러리(파일) 전체에 공개"되기 때문에,
  // 같은 파일 안에 있는 다른 클래스들(_TopBar, _WifiCard 등)에서도
  // HomeScreen._labelColor 처럼 그대로 가져다 쓸 수 있다.
  static const _bg = Color(0xFFF4F4F4); // 화면 배경(연회색)
  static const _labelColor = Color(0xFF505050); // 진한 글자색(제목류)
  static const _statusColor = Color(0xFF7A7A7A); // 옅은 글자색(상태 목록)
  static const _captionColor = Color(0xFF7F7F7F); // 옅은 글자색(카드 라벨)
  static const _brandBlue = Color(0xFF4ABEFF); // 앱 브랜드 파란색

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
            const _TopBar(), // 맨 위 흰 배경 바: 로고 + 설정/알림 아이콘
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 24),
              child: Column(
                children: [
                  // "내 기기" 제목
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 38),
                    child: _DeviceTitleRow(),
                  ),
                  const SizedBox(height: 4),
                  // 온라인 / 연결됨 / 배터리 상태 3줄
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 38),
                    child: _StatusList(),
                  ),
                  const SizedBox(height: 20),
                  // 로봇 기기 아바타 + 좌우 이전/다음 화살표
                  const _DeviceCarousel(),
                  const SizedBox(height: 16),
                  // 기기 닉네임("내 기기") + 편집 아이콘 + 모델명("TM-01")
                  // + 페이지네이션 점(여러 기기 중 몇 번째인지)
                  const _DeviceNicknameBlock(),
                  const SizedBox(height: 16),
                  // "기기 상태" 소제목 + "3분전 동기화됨" 캡션
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: _DeviceStatusHeaderRow(),
                  ),
                  const SizedBox(height: 12),
                  // 위치 카드(지도) + WIFI 카드, 가로로 나란히
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: _StatusCardsRow(),
                  ),
                  const SizedBox(height: 12),
                  // "현재 루틴" 카드
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: _RoutineCard(),
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

/// 화면 맨 위, 흰 배경의 상단 바. Tomo 로고(좌) + 설정 톱니바퀴 + 알림 벨(우).
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
              // 아이콘들은 오른쪽 끝에 붙게 밀어준다.
              const Spacer(),
              _IconButtonAsset(
                asset: 'assets/images/home_gear.svg',
                size: 24,
                // 설정 화면이 아직 없어서, 지금은 눌러도 아무 일도 안 일어남.
                onTap: () {},
              ),
              const SizedBox(width: 11),
              const _NotificationBellButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// SVG 아이콘 하나를 누를 수 있는 버튼으로 감싸주는 공용 위젯.
/// 아이콘 자체보다 살짝 넓게(padding 10) 눌리는 영역을 잡아서 손가락으로
/// 누르기 쉽게 했다.
class _IconButtonAsset extends StatelessWidget {
  const _IconButtonAsset({
    required this.asset,
    required this.size,
    required this.onTap,
  });

  final String asset;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SvgPicture.asset(asset, width: size, height: size),
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

/// "내 기기" 제목 텍스트 + 옆에 작은 깃발 모양 장식 아이콘.
class _DeviceTitleRow extends StatelessWidget {
  const _DeviceTitleRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '내 기기',
          style: TextStyle(
            color: HomeScreen._labelColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 4),
        SizedBox(
          width: 7,
          height: 7,
          child: _AssetIcon('assets/images/home_title_accent.svg'),
        ),
      ],
    );
  }
}

/// `SvgPicture.asset(...)` 한 줄을 매번 반복해서 쓰지 않으려고 만든
/// 아주 얇은 래퍼(wrapper) 위젯. 이 파일 안에서 아이콘을 넣을 때마다
/// `_AssetIcon('assets/images/...svg')` 형태로 짧게 쓸 수 있게 해준다.
class _AssetIcon extends StatelessWidget {
  const _AssetIcon(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, fit: BoxFit.contain);
}

/// "온라인 / 연결됨 / 95%" 3줄짜리 기기 상태 요약 목록.
class _StatusList extends StatelessWidget {
  const _StatusList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(label: '온라인', useOnlineDot: true),
        SizedBox(height: 5),
        _StatusRow(label: '연결됨', useWifiArc: true),
        SizedBox(height: 5),
        _StatusRow(label: '95%', useBattery: true),
      ],
    );
  }
}

/// 상태 목록 한 줄(아이콘 + 텍스트). 세 줄 모두 레이아웃은 똑같고 아이콘
/// 종류만 다르기 때문에, "어떤 아이콘을 쓸지"를 세 개의 bool 플래그로
/// 받아서 하나의 위젯으로 재사용한다.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    this.useOnlineDot = false,
    this.useWifiArc = false,
    this.useBattery = false,
  });

  final String label;
  final bool useOnlineDot;
  final bool useWifiArc;
  final bool useBattery;

  @override
  Widget build(BuildContext context) {
    // 세 플래그 중 어떤 것이 켜져 있는지에 따라 실제로 그릴 아이콘을 고른다.
    Widget rowIcon;
    if (useOnlineDot) {
      // "온라인" 상태는 아이콘 이미지가 아니라 그냥 초록색 동그라미다.
      // 단색 원 하나짜리라서 SVG 파일 없이 Container로 직접 그렸다.
      rowIcon = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF1ED342),
          shape: BoxShape.circle,
        ),
      );
    } else if (useWifiArc) {
      rowIcon = const SizedBox(
        width: 10,
        height: 8,
        child: _AssetIcon('assets/images/home_wifi_arc.svg'),
      );
    } else if (useBattery) {
      // 배터리 아이콘 원본 SVG는 세로로(5x10) 그려져 있어서, 가로로
      // 눕히려고 RotatedBox로 90도 돌린다. RotatedBox는 안쪽 SizedBox의
      // 가로/세로 크기(5x10)를 돌려서 바깥으로는 10x5짜리 박스처럼
      // 동작하게 만들어준다.
      rowIcon = const RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: 5,
          height: 10,
          child: _AssetIcon('assets/images/home_battery.svg'),
        ),
      );
    } else {
      rowIcon = const SizedBox(width: 7, height: 7);
    }

    return Row(
      children: [
        // 아이콘들 크기가 서로 달라도(7x7, 10x8, 10x5) 텍스트 시작 위치가
        // 항상 똑같이 맞도록, 고정 폭(12) 박스 안에 아이콘을 가운데
        // 정렬해서 넣는다.
        SizedBox(width: 12, child: Center(child: rowIcon)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: HomeScreen._statusColor,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

/// 로봇 모양 기기 아바타 + 좌우의 "이전/다음 기기" 화살표.
/// 여러 개의 기기(예: 형제자매 각각의 워치)를 좌우로 넘겨보는 캐러셀
/// UI인데, 지금은 실제로 여러 기기 데이터가 없어서 화살표를 눌러도
/// 아무 반응이 없다(자리만 잡아둔 상태).
class _DeviceCarousel extends StatelessWidget {
  const _DeviceCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 149,
      child: Row(
        children: [
          // 왼쪽 화살표 자리를 폭 103으로 고정해두고, 오른쪽은 92로 다르게
          // 준 이유는 원본 Figma 디자인에서 로봇 아바타가 화면 정중앙이
          // 아니라 살짝 왼쪽으로 치우쳐 있기 때문 — 그 미묘한 비대칭을
          // 그대로 재현했다.
          SizedBox(
            width: 103,
            child: Center(
              child: InkResponse(
                onTap: () {},
                radius: 20,
                // 화살표 SVG 원본은 위쪽을 가리키는 모양(^)이라, 왼쪽
                // 화살표(‹)로 쓰려면 반시계 방향으로 90도(quarterTurns: 3)
                // 돌려야 한다.
                child: const RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    width: 18,
                    height: 10,
                    child: _AssetIcon('assets/images/home_chevron_prev.svg'),
                  ),
                ),
              ),
            ),
          ),
          // Expanded: 남은 가로 공간을 전부 차지 → 그 안에서 로봇 아바타를
          // Center로 가운데 정렬.
          const Expanded(
            child: Center(
              child: SizedBox(
                width: 143,
                height: 149,
                child: _AssetIcon('assets/images/device_icon.svg'),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Center(
              child: InkResponse(
                onTap: () {},
                radius: 20,
                // 오른쪽 화살표(›)는 시계 방향으로 90도(quarterTurns: 1).
                child: const RotatedBox(
                  quarterTurns: 1,
                  child: SizedBox(
                    width: 18,
                    height: 10,
                    child: _AssetIcon('assets/images/home_chevron_next.svg'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 로봇 아바타 아래쪽: 기기 닉네임("내 기기") + 편집 연필 아이콘 + 점선
/// 밑줄 + 모델명("TM-01") + 페이지네이션 점(여러 기기 중 몇 번째인지).
///
/// 닉네임/모델명은 일반 Text가 아니라 이미지(SVG)로 되어 있는데, Figma
/// 디자인에서 손글씨 느낌의 커스텀 폰트를 썼고 그 폰트를 앱에 내려받지
/// 않았기 때문에 Figma가 내보낼 때부터 이미 "글자 모양을 그대로 그린
/// 그림"으로 나왔다 — 그래서 여기서도 Text 대신 이미지로 넣었다.
class _DeviceNicknameBlock extends StatelessWidget {
  const _DeviceNicknameBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          // 닉네임 이미지와 연필 아이콘의 "아래쪽 끝"이 서로 맞도록
          // 정렬(end)한다.
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 53.7,
              height: 17.37,
              child: _AssetIcon('assets/images/home_nickname_label.svg'),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: const SizedBox(
                width: 9,
                height: 9,
                child: _AssetIcon('assets/images/home_pencil.svg'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const SizedBox(
          width: 64,
          height: 2,
          child: _AssetIcon('assets/images/home_dash_line.svg'),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: 28.37,
          height: 7.94,
          child: _AssetIcon('assets/images/home_tm01_label.svg'),
        ),
        const SizedBox(height: 12),
        const _PaginationDots(),
      ],
    );
  }
}

/// 캐러셀 아래 작은 점 5개(첫 번째만 파란색=선택됨, 나머지는 회색).
/// 지금은 실제로 여러 기기가 있는 게 아니라 디자인 그대로 정적으로
/// 표시만 한다.
class _PaginationDots extends StatelessWidget {
  const _PaginationDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      // List.generate(5, ...): 인덱스 0~4에 대해 점을 하나씩 만든다.
      // index == 0 인 것(첫 번째 점)만 파란색으로 칠해서 "지금 이
      // 기기가 선택돼 있다"는 걸 표시한다.
      children: List.generate(5, (index) {
        final active = index == 0;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? HomeScreen._brandBlue : const Color(0xFFD9D9D9),
          ),
        );
      }),
    );
  }
}

/// "기기 상태" 소제목 + 오른쪽에 작게 붙는 "3분전 동기화됨" 캡션.
/// 화면 전체 폭을 채우는 게 아니라 텍스트 두 개가 딱 붙어 왼쪽에 몰려있는
/// 배치라서, 자식들을 화면 양 끝으로 밀어내는 Spacer 없이 그냥 Row에
/// 순서대로 나열했다.
class _DeviceStatusHeaderRow extends StatelessWidget {
  const _DeviceStatusHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '기기 상태',
          style: TextStyle(
            color: HomeScreen._labelColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 6),
        Text(
          '3분전 동기화됨',
          style: TextStyle(
            color: HomeScreen._statusColor,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

/// 흰 배경 + 둥근 모서리 + 옅은 그림자를 가진 "카드" 스타일을 만들어주는
/// 공용 함수. 위치 카드/WIFI 카드/루틴 카드가 전부 이 스타일을 그대로
/// 쓰기 때문에 함수 하나로 빼서 중복을 줄였다.
BoxDecoration _cardDecoration({double radius = 25}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
    ],
  );
}

/// "위치" 카드와 "WIFI" 카드를 가로로 나란히 배치하는 행.
/// 위치 카드는 폭이 고정(176)돼 있고, WIFI 카드는 Expanded로 남는 공간을
/// 전부 차지하도록 했다 — 그래서 화면 폭이 조금 달라져도 WIFI 카드 쪽만
/// 늘었다 줄었다 하고, 위치 카드(지도 이미지)는 항상 같은 크기를 유지한다.
class _StatusCardsRow extends StatelessWidget {
  const _StatusCardsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 176, height: 162, child: _LocationCard()),
        SizedBox(width: 10),
        Expanded(child: SizedBox(height: 162, child: _WifiCard())),
      ],
    );
  }
}

/// 지도 카드. 배경에 지도 스크린샷(정적 이미지, 실제 지도 SDK 연동은
/// 아직 안 함) 위에 위치 핀 여러 개와, 반투명한 "위치" 라벨 필(pill)을
/// 겹쳐서 그린다.
class _LocationCard extends StatelessWidget {
  const _LocationCard();

  // 지도 위에 흩뿌려진 위치 핀들의 좌표(카드 왼쪽 위 기준 상대 좌표)와 색.
  // 좌표는 Figma 디자인에 있던 값을 그대로 옮겨 적었다 — 실제 위치 데이터가
  // 아니라 디자인에서 정해둔 장식용 점들이다.
  static const _pins = <_MapPin>[
    _MapPin(left: 102, top: 97, color: Color(0xFFFF4A50)), // 강조색 핀(나)
    _MapPin(left: 138, top: 106, color: HomeScreen._brandBlue),
    _MapPin(left: 105, top: 109, color: HomeScreen._brandBlue),
    _MapPin(left: 97, top: 117, color: HomeScreen._brandBlue),
    _MapPin(left: 127, top: 106, color: HomeScreen._brandBlue),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // 카드 모서리를 둥글게 자르고, 그 안에 지도 이미지 + 핀 + 라벨을
      // Stack으로 겹쳐 쌓는다(지도가 맨 아래, 핀과 라벨이 그 위).
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_map_thumbnail.png',
            fit: BoxFit.cover,
          ),
          // 핀들을 하나씩 정확한 좌표(Positioned)에 배치.
          for (final pin in _pins)
            Positioned(
              left: pin.left,
              top: pin.top,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: pin.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // 카드 왼쪽 위에 떠 있는 반투명 흰색 "위치 ›" 라벨.
          Positioned(
            left: 6,
            top: 4,
            child: Container(
              width: 163,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(19),
              ),
              padding: const EdgeInsets.only(left: 20, right: 11),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  Text(
                    '위치',
                    style: TextStyle(
                      color: HomeScreen._captionColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Spacer(),
                  // "더보기" 느낌의 작은 우측 화살표(›). 원본 아이콘이
                  // 위쪽(^)을 가리키므로 90도 돌려서 오른쪽을 가리키게 함.
                  RotatedBox(
                    quarterTurns: 1,
                    child: SizedBox(
                      width: 7,
                      height: 4,
                      child: _AssetIcon('assets/images/home_chevron_small.svg'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 지도 위 핀 하나의 위치(카드 기준 상대 좌표)와 색을 담는 아주 단순한
/// 데이터 클래스. Widget이 아니라 그냥 값 묶음이라서 build()가 없다.
class _MapPin {
  const _MapPin({required this.left, required this.top, required this.color});

  final double left;
  final double top;
  final Color color;
}

/// "WIFI" 카드: 연결 상태 + 가족 구성원별 기기 3개의 온라인 상태 점 목록.
class _WifiCard extends StatelessWidget {
  const _WifiCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(22, 9, 22, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // spaceBetween: 자식들(헤더/연결됨/멤버3줄/점) 사이 간격을 카드
        // 안에서 균등하게 벌려서, 카드 높이가 딱 고정(162)이어도 내용이
        // 위아래로 꽉 차 보이게 한다. 고정된 SizedBox(height: ..)를
        // 하나하나 넣는 대신 이 방식을 쓴 이유는, 폰트 렌더링에 따라
        // 텍스트 줄 높이가 미세하게 달라져도 자동으로 맞춰지기 때문이다.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text(
                'WIFI',
                style: TextStyle(
                  color: HomeScreen._captionColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1, // 줄 간격을 폰트 크기와 딱 맞춰서(1배) 카드가
                  // 좁을 때도 텍스트 위아래 여백이 과하게 생기지 않게 함.
                ),
              ),
              Spacer(),
              RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: 7,
                  height: 4,
                  child: _AssetIcon('assets/images/home_chevron_small.svg'),
                ),
              ),
            ],
          ),
          const Text(
            '연결됨',
            style: TextStyle(
              color: HomeScreen._labelColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          // 가족 구성원 3명의 기기 상태 줄. 색만 다르고(초록/주황/빨강)
          // 레이아웃은 동일해서 _WifiMemberRow 하나로 재사용한다.
          const _WifiMemberRow(color: Color(0xFF1ED342), name: '지예님의 기기'),
          const _WifiMemberRow(color: Color(0xFFFF9A47), name: '예담님의 기기'),
          const _WifiMemberRow(color: Color(0xFFFF4343), name: '예소님의 기기'),
          // 맨 아래 "더 있어요"를 뜻하는 점 3개(・・・).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Container(
                width: 2.18,
                height: 2.18,
                margin: const EdgeInsets.symmetric(horizontal: 1.4),
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// WIFI 카드 안, 가족 구성원 한 명의 기기 상태를 나타내는 한 줄
/// (색 점 + 이름). 점 색깔로 온라인/자리비움 등 상태를 구분하는
/// 컨셉으로 보이는데, 지금은 디자인값 그대로 정적으로 표시만 한다.
class _WifiMemberRow extends StatelessWidget {
  const _WifiMemberRow({required this.color, required this.name});

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7.09,
          height: 7.09,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            color: HomeScreen._captionColor,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// "현재 루틴" 카드: 오늘 등록된 루틴 중 가장 이른 시간의 루틴 하나를
/// 요약해서 보여준다.
///
/// Hive에 저장된 실제 루틴 데이터([routinesForDateProvider])를 구독하는
/// `ConsumerWidget`이라, 루틴 탭에서 "+"로 루틴을 새로 추가하면 이 카드도
/// 자동으로 갱신된다. 오늘 등록된 루틴이 하나도 없으면 안내 문구만
/// 보여준다.
///
/// 예전에는 이 카드를 누르면 루틴 화면(`/routine`)으로 넘어갔지만, 하단
/// 탭바의 "루틴" 아이콘으로도 충분히 갈 수 있어서 탭 이동 기능은 뺐다 —
/// 이제는 그냥 요약 정보만 보여주는 카드다.
class _RoutineCard extends ConsumerWidget {
  const _RoutineCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayRoutines = ref.watch(
      routinesForDateProvider(DateTime(today.year, today.month, today.day)),
    );
    // routinesForDateProvider는 이미 시간순으로 정렬해서 주기 때문에,
    // 첫 번째 항목이 곧 "오늘 가장 이른 루틴" = "현재 루틴"이다.
    final routine = todayRoutines.isEmpty ? null : todayRoutines.first;

    return Container(
      // width: double.infinity를 안 주면, 내용이 전부 Text뿐일 때
      // (예: "오늘 등록된 루틴이 없어요") Column이 그 글자 폭만큼만
      // 차지해서 카드가 원래보다 훨씬 좁아 보인다 — 위치/WIFI 카드와
      // 같은 폭으로 항상 꽉 채우도록 명시한다.
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(23, 16, 23, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '현재 루틴',
            style: TextStyle(
              color: HomeScreen._captionColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          if (routine == null)
            const Text(
              '오늘 등록된 루틴이 없어요',
              style: TextStyle(
                color: HomeScreen._captionColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            )
          else
            Row(
              children: [
                Text(
                  '${_timeLabel(routine.dateTime)} ${routine.title}',
                  style: const TextStyle(
                    color: HomeScreen._labelColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '・${routine.tag}',
                  style: const TextStyle(
                    color: HomeScreen._captionColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// [dateTime]의 시/분만 "11:00"처럼 두 자리씩 맞춰 문자열로 바꾼다.
  static String _timeLabel(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
