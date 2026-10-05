/// 반복으로 만든 루틴을 고치거나 지울 때 "어디까지 적용할지"
/// (`docs/API.md` 9장의 `scope` 쿼리). 반복 루틴은 날짜마다 따로 저장된
/// 행이 같은 `seriesId`로 묶여 있기 때문에 고르게 한다.
enum ChangeScope {
  /// 지금 보고 있는 그 날짜의 루틴만.
  single('single'),

  /// 같은 반복에 속한 **오늘 이후** 날짜들 전체(고른 날짜 포함). 서버는 지난
  /// 날짜의 같은 반복 루틴은 건드리지 않는다 — 지난 기록은 그때 하기로 했던
  /// 내용을 그대로 남겨야 해서다.
  series('series');

  const ChangeScope(this.code);

  /// 서버로 보낼 쿼리 값.
  final String code;
}
