/// `POST /api/admin/stock/outbound/confirm` 요청 본문 (PLAN 2609_28 D12).
///
/// 서버는 `lines` 배열을 받지만 화면은 **물품 1줄마다 1건**만 보낸다 — 중단 복구를 위해서다.
/// 수량은 양수로 보내고 서버가 음수로 저장한다.
class ConfirmOutboundParams {
  final int orderLineId;
  final int productId;
  final int quantity;

  /// YYYY-MM-DD
  final String movedOn;

  const ConfirmOutboundParams({
    required this.orderLineId,
    required this.productId,
    required this.quantity,
    required this.movedOn,
  });

  Map<String, dynamic> toJson() => {
        'orderLineId': orderLineId,
        'lines': [
          {'productId': productId, 'quantity': quantity},
        ],
        'movedOn': movedOn,
      };
}
