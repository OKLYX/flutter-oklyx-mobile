import 'package:equatable/equatable.dart';

import '../../domain/entities/order_item.dart';

/// One line of the same 11st delivery
/// (GET /api/orders/{orderItemId}/elevenst-delivery-lines, FEATURE_2610_17 / D64).
///
/// **Purpose**: the line pickers of 「일부 줄만 보내기」 and
/// 「한 줄을 송장 여러 장으로」 on the order detail.
///
/// ⚠️ [addOn] is the server's flag (11st `addPrdYn`) — add-on lines alone
/// cannot be sent partially.
class ElevenstDeliveryLine extends Equatable {
  final int orderItemId;
  final String? itemName;
  final int orderQty;
  final OrderStatus status;
  final bool addOn;

  const ElevenstDeliveryLine({
    required this.orderItemId,
    required this.itemName,
    required this.orderQty,
    required this.status,
    required this.addOn,
  });

  factory ElevenstDeliveryLine.fromJson(Map<String, dynamic> json) =>
      ElevenstDeliveryLine(
        orderItemId: (json['orderItemId'] as num?)?.toInt() ?? 0,
        itemName: json['itemName'] as String?,
        orderQty: (json['orderQty'] as num?)?.toInt() ?? 0,
        status: orderStatusFrom(json['status'] as String?),
        addOn: json['addOn'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [orderItemId, itemName, orderQty, status, addOn];
}
