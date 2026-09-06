/// 주문 항목 엔티티 (프론트 OrderEntity의 OrderItem과 동일 필드)
///
/// Coupang 등 외부 마켓플레이스에서 동기화된 단일 주문 항목.
/// 백엔드 GET /api/orders 응답의 각 원소에 매핑된다.
class OrderItem {
  final int id;
  final int marketplaceAccountId;
  final String platform;
  final String externalOrderId;
  final String? externalBoxId;
  final String externalItemId;
  final String? itemName;
  final String? ordererName;
  final String? receiverName;
  final int orderCount;
  final int cancelCount;
  final int holdCount;
  final int purchasableQty;
  final String status;
  final String? paidAt;

  const OrderItem({
    required this.id,
    required this.marketplaceAccountId,
    required this.platform,
    required this.externalOrderId,
    this.externalBoxId,
    required this.externalItemId,
    this.itemName,
    this.ordererName,
    this.receiverName,
    required this.orderCount,
    required this.cancelCount,
    required this.holdCount,
    required this.purchasableQty,
    required this.status,
    this.paidAt,
  });
}

/// Coupang order status codes in workflow sequence; used for the status filter
/// buttons (프론트 OrderEntity.ORDER_STATUSES와 동일).
const List<String> kOrderStatuses = [
  'ACCEPT',
  'INSTRUCT',
  'DEPARTURE',
  'DELIVERING',
  'FINAL_DELIVERY',
  'NONE_TRACKING',
];

// Maps Coupang order status codes to Korean display labels (프론트와 동일).
const Map<String, String> _orderStatusLabels = {
  'ACCEPT': '결제완료',
  'INSTRUCT': '상품준비중',
  'DEPARTURE': '배송지시',
  'DELIVERING': '배송중',
  'FINAL_DELIVERY': '배송완료',
  // 전량취소된 주문의 표시용 — 마켓 status 는 그대로지만 취소 결과가 이 코드를 내려준다
  // (FEATURE_2609_25, 웹 OrderEntity 와 같은 라벨).
  'CANCELLED': '취소',
  // Short label so the status filter chip fits one line; the full explanation
  // is shown under the filter bar when this status is selected.
  'NONE_TRACKING': '추적불가',
};

/// Returns the Korean label for an order status code; falls back to the raw value.
String getOrderStatusLabel(String status) =>
    _orderStatusLabels[status] ?? status;

/// 이미 발송된(배송지시 이상) 상태 — 신규 업로드가 아니라 송장 "수정" 대상이다.
/// 판정은 서버가 한다(PLAN 2609_11 D3). 화면에서는 버튼 라벨·안내문에만 쓴다.
const List<String> kShippedStatuses = [
  'DEPARTURE',
  'DELIVERING',
  'FINAL_DELIVERY',
  'NONE_TRACKING',
];

bool isAlreadyShipped(String status) => kShippedStatuses.contains(status);

/// 출고관리 화면 대상 — 아직 발송하지 않은 주문(PLAN 2609_15 D1).
const List<String> kShipmentStatuses = ['ACCEPT', 'INSTRUCT'];

/// 전량취소 여부 — 쿠팡은 전량취소된 주문도 원래 status(ACCEPT 등)를 그대로 둔다.
/// 그래서 상태 코드가 아니라 수량으로 판정한다(프론트 OrderEntity.isFullyCanceled 와 동일 규칙).
/// 부분취소(cancelCount < orderCount)는 원래 상태에 그대로 남는다.
bool isFullyCanceled(OrderItem order) =>
    order.cancelCount > 0 && order.cancelCount == order.orderCount;

/// 좁은 목록 카드용 단일 "고객" 표기. 택배가 향하는 쪽이 수취인이라 수취인이
/// 우선이고, 선물 주문(주문자 != 수취인)은 상세 페이지에서 둘 다 보여준다
/// (프론트 getCustomerName 과 동일 규칙).
String getCustomerName(OrderItem order) =>
    order.receiverName ?? order.ordererName ?? '-';

/// 검색 대상 칩. 기본은 고객명(PLAN D10).
enum OrderSearchField { customer, orderNo }

/// 공백 제거 + 소문자화 — '김 철수'와 '김철수'를 같게 본다.
String _normalize(String v) => v.replaceAll(RegExp(r'\s+'), '').toLowerCase();

/// 고객명은 주문자·수취인 **둘 다** 본다(선물 주문은 다르다). 빈 검색어는 전부 통과.
bool matchesOrderSearch(OrderItem order, OrderSearchField field, String term) {
  final needle = _normalize(term);
  if (needle.isEmpty) return true;
  if (field == OrderSearchField.orderNo) {
    return _normalize(order.externalOrderId).contains(needle);
  }
  return [order.ordererName, order.receiverName]
      .any((n) => n != null && _normalize(n).contains(needle));
}
