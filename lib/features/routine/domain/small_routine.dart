/// 스몰루틴(SmallRoutine) — 빅루틴 하나 안에 들어가는 "할 일" 한 칸.
///
/// 기획 문서(Figma "앱 초안" 노트 2번)에 따르면 스몰루틴은:
///  - 개별적으로 시간을 갖지 않는다 (빅루틴이 이미 8:00~12:00 같은 시간 범위를 갖고 있고,
///    그 시간 범위 "안에서" 순서대로 하나씩 처리하는 개념).
///  - 순서가 있는 "연속적인 할 일" 목록이다.
///    예: 1.씻기 → 2.문잠구기 → 3.301번버스타기 → 4.약국도착하기 → 5.집복귀
///
/// 그래서 SmallRoutine은 `order`(순서)와 `title`만 있으면 되고,
/// 완료 여부(`isDone`)는 워치에서 "미션 성공" 처리가 됐을 때 true로 바뀐다고 가정한다.
/// (워치 ↔ 앱 동기화는 아직 GATT 스펙이 안 나와서, 지금은 앱에서 직접 체크할 수 있는
/// 로컬 상태로만 구현해뒀다 — 나중에 BleService 쪽에서 동기화 이벤트가 오면
/// 이 isDone 값을 갱신해주는 코드를 추가하면 된다.)
class SmallRoutine {
  const SmallRoutine({
    required this.id,
    required this.order,
    required this.title,
    this.isDone = false,
  });

  /// 스몰루틴 고유 id. Hive에는 키-값으로 저장하지 않고 BigRoutine 안에
  /// 리스트(Map의 리스트)로 통째로 저장하기 때문에, 여기서는 리스트 안에서
  /// 항목을 구분하기 위한 용도로만 쓰인다 (수정/삭제 시 어떤 항목인지 찾기 위함).
  final String id;

  /// 몇 번째 할 일인지. 리스트의 index로 정렬하면 될 것 같지만, 사용자가
  /// 드래그로 순서를 바꾸는 UX(ReorderableListView)를 지원하려면 순서 값을
  /// 명시적으로 들고 있는 게 버그를 줄이는 데 더 안전하다.
  final int order;

  final String title;

  final bool isDone;

  /// 불변(immutable) 모델이라 값 하나를 바꾸고 싶을 때도 새 인스턴스를 만들어야 한다.
  /// Dart/Flutter에서 상태를 다룰 때 흔히 쓰는 관례(copyWith 패턴)인데,
  /// "기존 값은 그대로 두고 넘겨준 필드만 바꾼 새 객체"를 만들어준다.
  SmallRoutine copyWith({int? order, String? title, bool? isDone}) {
    return SmallRoutine(
      id: id,
      order: order ?? this.order,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  /// Hive는 Dart 객체를 그대로 저장하지 못하고(코드 생성을 안 쓰기로 했으므로)
  /// Map/List/String/num/bool 같은 원시 타입만 저장할 수 있다.
  /// 그래서 모델 <-> Map 변환 메서드를 직접 짜서 쓴다.
  factory SmallRoutine.fromMap(Map<String, dynamic> map) {
    return SmallRoutine(
      id: map['id'] as String,
      order: map['order'] as int,
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'order': order, 'title': title, 'isDone': isDone};
  }
}
