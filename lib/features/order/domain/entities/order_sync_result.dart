import 'order_item.dart';

/// 주문 동기화 결과 엔티티 (프론트 OrderSyncResponse와 동일)
///
/// POST /api/orders/sync 응답에 매핑된다. 동기화로 갱신된 주문 목록 전체와
/// 신규/수정/취소 건수를 함께 담는다.
class OrderSyncResult {
  final String syncedAt;
  final int newOrders;
  final int updatedOrders;
  final int canceledUpdated;
  final List<OrderItem> orders;

  const OrderSyncResult({
    required this.syncedAt,
    required this.newOrders,
    required this.updatedOrders,
    required this.canceledUpdated,
    required this.orders,
  });
}
