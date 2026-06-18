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
  'NONE_TRACKING': '업체 직접 배송(배송 연동 미적용), 추적불가',
};

/// Returns the Korean label for an order status code; falls back to the raw value.
String getOrderStatusLabel(String status) =>
    _orderStatusLabels[status] ?? status;
