import '../../domain/entities/outbound_order.dart';

class OutboundProductLineModel extends OutboundProductLine {
  const OutboundProductLineModel({
    required super.productId,
    required super.productName,
    required super.requiredQty,
    required super.confirmedQty,
  });

  factory OutboundProductLineModel.fromJson(Map<String, dynamic> json) {
    return OutboundProductLineModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      requiredQty: json['requiredQty'] as int? ?? 0,
      confirmedQty: json['confirmedQty'] as int? ?? 0,
    );
  }
}

class OutboundOrderModel extends OutboundOrder {
  const OutboundOrderModel({
    required super.orderLineId,
    required super.externalOrderId,
    required super.itemName,
    super.status,
    super.orderedAt,
    required super.sellerId,
    required super.sellerName,
    required super.orderQty,
    required super.products,
  });

  factory OutboundOrderModel.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>?) ?? const [];
    return OutboundOrderModel(
      orderLineId: json['orderLineId'] as int,
      externalOrderId: json['externalOrderId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      status: json['status'] as String?,
      orderedAt: json['orderedAt'] as String?,
      sellerId: json['sellerId'] as int? ?? 0,
      sellerName: json['sellerName'] as String? ?? '',
      orderQty: json['orderQty'] as int? ?? 0,
      products: products
          .map((e) =>
              OutboundProductLineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OutboundUnexpandedModel extends OutboundUnexpanded {
  const OutboundUnexpandedModel({
    required super.orderLineId,
    required super.externalOrderId,
    required super.itemName,
    required super.reason,
  });

  factory OutboundUnexpandedModel.fromJson(Map<String, dynamic> json) {
    return OutboundUnexpandedModel(
      orderLineId: json['orderLineId'] as int,
      externalOrderId: json['externalOrderId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class OutboundResultModel extends OutboundResult {
  const OutboundResultModel({required super.orders, required super.unexpanded});

  factory OutboundResultModel.fromJson(Map<String, dynamic> json) {
    final orders = (json['orders'] as List<dynamic>?) ?? const [];
    final unexpanded = (json['unexpanded'] as List<dynamic>?) ?? const [];
    return OutboundResultModel(
      orders: orders
          .map((e) => OutboundOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unexpanded: unexpanded
          .map((e) =>
              OutboundUnexpandedModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
