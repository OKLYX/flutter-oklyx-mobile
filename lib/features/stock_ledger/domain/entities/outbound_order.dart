/// 출고 확인 화면의 데이터 (PLAN 2609_28 D11·D13).
///
/// 출고는 **주문에서 출발**한다 — 물품 검색으로 시작하면 어느 주문으로 나갔는지를 잃는다.
library;

/// 아직 안 나간 주문 라인 1건 + 소진할 물품 목록.
class OutboundOrder {
  final int orderLineId;
  final String externalOrderId;
  final String itemName;

  /// 중립 주문 상태 코드 원문 (`PAID` | `PREPARING`).
  final String? status;

  /// ISO-8601 주문 시각. 정렬은 서버가 오래된 순으로 이미 맞춰 준다.
  final String? orderedAt;

  final int sellerId;
  final String sellerName;
  final int orderQty;
  final List<OutboundProductLine> products;

  const OutboundOrder({
    required this.orderLineId,
    required this.externalOrderId,
    required this.itemName,
    this.status,
    this.orderedAt,
    required this.sellerId,
    required this.sellerName,
    required this.orderQty,
    required this.products,
  });

  /// 남은 수량이 하나도 없으면 카드가 목록에서 빠진다.
  bool get fullyConfirmed => products.every((p) => p.remainingQty <= 0);

  OutboundOrder copyWith({List<OutboundProductLine>? products}) => OutboundOrder(
        orderLineId: orderLineId,
        externalOrderId: externalOrderId,
        itemName: itemName,
        status: status,
        orderedAt: orderedAt,
        sellerId: sellerId,
        sellerName: sellerName,
        orderQty: orderQty,
        products: products ?? this.products,
      );
}

/// 주문 라인이 소진하는 물품 1건.
///
/// [requiredQty] = 마스터 BOM 수량 × 주문 수량, [confirmedQty] = 이미 기록된 출고(양수).
class OutboundProductLine {
  final int productId;
  final String productName;
  final int requiredQty;
  final int confirmedQty;

  const OutboundProductLine({
    required this.productId,
    required this.productName,
    required this.requiredQty,
    required this.confirmedQty,
  });

  int get remainingQty => requiredQty - confirmedQty;

  OutboundProductLine copyWith({int? confirmedQty}) => OutboundProductLine(
        productId: productId,
        productName: productName,
        requiredQty: requiredQty,
        confirmedQty: confirmedQty ?? this.confirmedQty,
      );
}

/// 구성 물품을 전개하지 못한 주문 라인.
///
/// 🔴 목록에서 빼면 재고가 조용히 틀린다 — 화면은 이 섹션을 **항상** 보여주고 접지 않는다(D13).
class OutboundUnexpanded {
  final int orderLineId;
  final String externalOrderId;
  final String itemName;

  /// 서버 원문 코드 (`UNMAPPED_OPTION` | `NO_MASTER_OPTION` | `EMPTY_BOM`).
  final String reason;

  const OutboundUnexpanded({
    required this.orderLineId,
    required this.externalOrderId,
    required this.itemName,
    required this.reason,
  });
}

/// `GET /api/admin/stock/outbound` 응답 묶음.
class OutboundResult {
  final List<OutboundOrder> orders;
  final List<OutboundUnexpanded> unexpanded;

  const OutboundResult({required this.orders, required this.unexpanded});
}
