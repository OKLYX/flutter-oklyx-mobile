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

  /// 플랫폼 중립 상태 — 화면·필터·전송 판정은 이 값만 본다(FEATURE_2609_26 D4).
  final OrderStatus status;

  /// 플랫폼 원문 상태(쿠팡 `ACCEPT` 등). 거울 행이 없으면 null.
  /// 표시·분기에 쓰지 말 것 — 예외는 상세의 추적불가 표기 하나다(D5).
  final String? platformStatus;

  /// 전량취소 여부 — **서버가 판정한다**(cancel + hold >= order, PLAN D26).
  /// 앱에서 수량으로 다시 판정하지 말 것.
  final bool cancelled;

  final String? paidAt;

  /// 주문 시점 금액 스냅샷 (PLAN D9·D10). 과거 주문은 백필된 만큼만 채워지므로 nullable 이다.
  /// ⚠️ null 을 0 으로 바꿔 표시하지 말 것 — "모름"과 "0원"은 다르다.
  final int? unitPrice;
  final int? lineAmount;
  final int? discountAmount;
  final int? platformDiscountAmount;

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
    this.platformStatus,
    this.cancelled = false,
    this.paidAt,
    this.unitPrice,
    this.lineAmount,
    this.discountAmount,
    this.platformDiscountAmount,
  });
}

/// 플랫폼 중립 주문 상태 (백엔드 `OrderStatus` 와 1:1, FEATURE_2609_26 D5).
///
/// [OrderStatus.unknown] 은 서버에만 있는 값을 받았을 때의 자리다 — 앱이 서버보다 늦게
/// 배포될 수 있어 파싱이 예외를 던지면 목록 전체가 죽는다.
enum OrderStatus { paid, preparing, shipped, delivering, delivered, cancelled, unknown }

/// 응답 문자열 → 중립 상태. 모르는 값은 [OrderStatus.unknown] 이다(예외·null 금지).
///
/// ❌ 쿠팡 코드(ACCEPT 등)를 여기서 매핑하지 말 것 — 플랫폼 매핑의 소유자는 백엔드다.
OrderStatus orderStatusFrom(String? raw) => switch (raw) {
      'PAID' => OrderStatus.paid,
      'PREPARING' => OrderStatus.preparing,
      'SHIPPED' => OrderStatus.shipped,
      'DELIVERING' => OrderStatus.delivering,
      'DELIVERED' => OrderStatus.delivered,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.unknown,
    };

/// 상태 필터 칩 후보 — 워크플로 순서.
///
/// ⚠️ 프론트와 **구조가 다르다**: 웹은 진행 5값 + 별도 취소 필터, 모바일은 취소를 포함한
/// 6값 통합이다(동작은 같다). 라벨·집합을 웹에서 그대로 옮기지 말 것.
const List<OrderStatus> kOrderStatuses = [
  OrderStatus.paid,
  OrderStatus.preparing,
  OrderStatus.shipped,
  OrderStatus.delivering,
  OrderStatus.delivered,
  OrderStatus.cancelled,
];

// Maps neutral order statuses to Korean display labels (프론트와 동일).
const Map<OrderStatus, String> _orderStatusLabels = {
  OrderStatus.paid: '결제완료',
  OrderStatus.preparing: '상품준비중',
  OrderStatus.shipped: '발송처리',
  OrderStatus.delivering: '배송중',
  OrderStatus.delivered: '배송완료',
  OrderStatus.cancelled: '취소',
};

/// Returns the Korean label for a neutral order status.
String getOrderStatusLabel(OrderStatus status) =>
    _orderStatusLabels[status] ?? '알 수 없음';

/// 이미 발송된(발송처리 이상) 상태 — 신규 업로드가 아니라 송장 "수정" 대상이다.
/// 판정은 서버가 한다(PLAN 2609_11 D3). 화면에서는 버튼 라벨·안내문에만 쓴다.
const List<OrderStatus> kShippedStatuses = [
  OrderStatus.shipped,
  OrderStatus.delivering,
  OrderStatus.delivered,
];

bool isAlreadyShipped(OrderStatus status) => kShippedStatuses.contains(status);

/// 출고관리 화면 대상 — 아직 발송하지 않은 주문(PLAN 2609_15 D1).
const List<OrderStatus> kShipmentStatuses = [
  OrderStatus.paid,
  OrderStatus.preparing,
];

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
