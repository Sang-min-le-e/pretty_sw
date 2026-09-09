import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../routine/data/routine_providers.dart';

/// 홈 화면(Figma node 392:5304)과 기기 상세 관리 화면(node 405:6598)이
/// 공유하는 "기기 상태 요약" 구역 위젯들.
///
/// 두 화면은 상단 바(홈은 로고+벨, 기기 상세는 뒤로가기+제목+설정)만
/// 다르고, 그 아래("OO의 기기" 제목부터 "현재 루틴" 카드까지)는 완전히
/// 똑같은 디자인이라 여기 한 곳에 모아두고 두 화면에서 가져다 쓴다.

const kDeviceOverviewLabelColor = Color(0xFF505050); // 진한 글자색(제목류)
const kDeviceOverviewStatusColor = Color(0xFF7A7A7A); // 옅은 글자색(상태 목록)
const kDeviceOverviewCaptionColor = Color(0xFF7F7F7F); // 옅은 글자색(카드 라벨)
const kDeviceOverviewBrandBlue = Color(0xFF4ABEFF);

/// `SvgPicture.asset(...)` 한 줄을 매번 반복해서 쓰지 않으려고 만든
/// 아주 얇은 래퍼(wrapper) 위젯.
class AssetIcon extends StatelessWidget {
  const AssetIcon(this.asset, {super.key});

  final String asset;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, fit: BoxFit.contain);
}

/// 흰 배경 + 둥근 모서리 + 옅은 그림자를 가진 "카드" 스타일을 만들어주는
/// 공용 함수. 연결된 기기 카드/루틴 카드가 전부 이 스타일을 그대로 쓴다.
BoxDecoration deviceCardDecoration({double radius = 25}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 4),
    ],
  );
}

/// "OO의 기기" 제목 텍스트 + 옆에 작은 깃발 모양 장식 아이콘.
class DeviceTitleRow extends StatelessWidget {
  const DeviceTitleRow({super.key, required this.deviceOwnerName});

  /// 기기 주인 이름. 화면마다 다른 기기를 보여줄 수 있어서 파라미터로 받는다
  /// (홈 화면은 지금 로그인한 계정과 연결된 첫 번째 자녀, 기기 상세 화면은
  /// 목록에서 고른 자녀).
  final String deviceOwnerName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$deviceOwnerName의 기기',
          style: const TextStyle(
            color: kDeviceOverviewLabelColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        const SizedBox(
          width: 7,
          height: 7,
          child: AssetIcon('assets/images/home_title_accent.svg'),
        ),
      ],
    );
  }
}

/// "온라인 / 연결됨 / 95%" 3줄짜리 기기 상태 요약 목록.
class DeviceStatusList extends StatelessWidget {
  const DeviceStatusList({super.key, this.onWifiTap});

  /// "연결됨"(WIFI) 줄을 눌렀을 때 할 일. 기기 상세 관리 화면에서만
  /// WIFI 설정 화면으로 연결하고(Figma "8-1의 WIFI칸 '>' 클릭 시"),
  /// 홈 화면에서는 null로 둬서 반응하지 않는다.
  final VoidCallback? onWifiTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusRow(label: '온라인', useOnlineDot: true),
        const SizedBox(height: 5),
        _StatusRow(label: '연결됨', useWifiArc: true, onTap: onWifiTap),
        const SizedBox(height: 5),
        const _StatusRow(label: '95%', useBattery: true),
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
    this.onTap,
  });

  final String label;
  final bool useOnlineDot;
  final bool useWifiArc;
  final bool useBattery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget rowIcon;
    if (useOnlineDot) {
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
        child: AssetIcon('assets/images/home_wifi_arc.svg'),
      );
    } else if (useBattery) {
      rowIcon = const RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: 5,
          height: 10,
          child: AssetIcon('assets/images/home_battery.svg'),
        ),
      );
    } else {
      rowIcon = const SizedBox(width: 7, height: 7);
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 12, child: Center(child: rowIcon)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: kDeviceOverviewStatusColor,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}

/// 로봇 모양 기기 아바타 + 좌우의 "이전/다음 기기" 화살표.
/// 여러 개의 기기(예: 형제자매 각각의 워치)를 좌우로 넘겨보는 캐러셀
/// UI인데, 지금은 실제로 여러 기기 데이터가 없어서 화살표를 눌러도
/// 아무 반응이 없다(자리만 잡아둔 상태).
class DeviceCarousel extends StatelessWidget {
  const DeviceCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 149,
      child: Row(
        children: [
          SizedBox(
            width: 103,
            child: Center(
              child: InkResponse(
                onTap: () {},
                radius: 20,
                child: const RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    width: 18,
                    height: 10,
                    child: AssetIcon('assets/images/home_chevron_prev.svg'),
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: SizedBox(
                width: 143,
                height: 149,
                child: AssetIcon('assets/images/device_icon.svg'),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Center(
              child: InkResponse(
                onTap: () {},
                radius: 20,
                child: const RotatedBox(
                  quarterTurns: 1,
                  child: SizedBox(
                    width: 18,
                    height: 10,
                    child: AssetIcon('assets/images/home_chevron_next.svg'),
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

/// 캐러셀 아래 작은 점 5개(첫 번째만 파란색=선택됨, 나머지는 회색).
/// 기기 상세 관리 화면에만 있고, 홈 화면 리디자인에서는 빠졌다.
class DevicePaginationDots extends StatelessWidget {
  const DevicePaginationDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index == 0;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? kDeviceOverviewBrandBlue : const Color(0xFFD9D9D9),
          ),
        );
      }),
    );
  }
}

/// "기기 상태" 소제목 + 오른쪽에 작게 붙는 "3분전 동기화됨" 캡션.
class DeviceStatusHeaderRow extends StatelessWidget {
  const DeviceStatusHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '기기 상태',
          style: TextStyle(
            color: kDeviceOverviewLabelColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 6),
        Text(
          '3분전 동기화됨',
          style: TextStyle(
            color: kDeviceOverviewStatusColor,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

/// "연결된 기기" 카드: 지금 이 가디언 계정에 연결된 기기 개수 + 가족
/// 구성원별 기기 3개의 온라인 상태 점 목록. [onTap]을 누르면 이 카드의
/// 전용 관리 화면(`ConnectedDevicesScreen`)으로 이동한다.
class ConnectedDevicesCard extends StatelessWidget {
  const ConnectedDevicesCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      height: 146,
      decoration: deviceCardDecoration(),
      padding: const EdgeInsets.fromLTRB(25, 14, 25, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                '연결된 기기',
                style: TextStyle(
                  color: kDeviceOverviewLabelColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              const Spacer(),
              const Text(
                '3개 기기 연결중',
                style: TextStyle(
                  color: kDeviceOverviewCaptionColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: 7,
                  height: 4,
                  child: AssetIcon('assets/images/home_chevron_small.svg'),
                ),
              ),
            ],
          ),
          const _ConnectedDeviceRow(color: Color(0xFFC8E093), name: '지예님의 기기'),
          const _ConnectedDeviceRow(color: Color(0xFFE1E1E1), name: '예담님의 기기'),
          const _ConnectedDeviceRow(color: Color(0xFFAA97D0), name: '예소님의 기기'),
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
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// "연결된 기기" 카드 안, 가족 구성원 한 명의 기기 상태를 나타내는 한 줄
/// (색 점 + 이름).
class _ConnectedDeviceRow extends StatelessWidget {
  const _ConnectedDeviceRow({required this.color, required this.name});

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
            color: kDeviceOverviewCaptionColor,
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
/// 요약해서 보여준다. Hive에 저장된 실제 루틴 데이터
/// ([routinesForDateProvider])를 구독하는 `ConsumerWidget`이라, 루틴 탭에서
/// "+"로 루틴을 새로 추가하면 이 카드도 자동으로 갱신된다.
class CurrentRoutineCard extends ConsumerWidget {
  const CurrentRoutineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayRoutines = ref.watch(
      routinesForDateProvider(DateTime(today.year, today.month, today.day)),
    );
    final routine = todayRoutines.isEmpty ? null : todayRoutines.first;

    return Container(
      width: double.infinity,
      decoration: deviceCardDecoration(),
      padding: const EdgeInsets.fromLTRB(23, 16, 23, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '현재 루틴',
                style: TextStyle(
                  color: kDeviceOverviewCaptionColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Spacer(),
              RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: 7,
                  height: 4,
                  child: AssetIcon('assets/images/home_chevron_small.svg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (routine == null)
            const Text(
              '오늘 등록된 루틴이 없어요',
              style: TextStyle(
                color: kDeviceOverviewCaptionColor,
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
                    color: kDeviceOverviewLabelColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '・${routine.tag}',
                  style: const TextStyle(
                    color: kDeviceOverviewCaptionColor,
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

  static String _timeLabel(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
