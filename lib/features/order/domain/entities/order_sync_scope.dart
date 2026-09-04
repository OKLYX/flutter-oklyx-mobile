/// 동기화가 조회할 주문 상태 범위 (백엔드 `OrderSyncScope`).
///
/// - [full]: 전 상태 (주문내역·구매목록)
/// - [active]: 결제완료·상품준비중만 (출고관리 — 쿠팡 왕복 6회 → 2회)
///
/// ⚠️ [wireValue] 는 백엔드 enum **이름 그대로**여야 한다. 대소문자가 다르면 서버가
///    400 이 아니라 500 을 준다(`MethodArgumentTypeMismatchException` 이 catch-all
///    로 빠지는 알려진 구멍).
enum OrderSyncScope {
  full('FULL'),
  active('ACTIVE');

  const OrderSyncScope(this.wireValue);

  final String wireValue;
}
