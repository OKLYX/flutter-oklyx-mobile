import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_period.dart';
import '../../domain/entities/order_sync_result.dart';

class OrderModel extends OrderItem {
  const OrderModel({
    required super.id,
    required super.marketplaceAccountId,
    required super.platform,
    required super.externalOrderId,
    super.externalBoxId,
    required super.externalItemId,
    super.itemName,
    super.ordererName,
    super.receiverName,
    required super.orderCount,
    required super.cancelCount,
    required super.holdCount,
    required super.purchasableQty,
    required super.status,
    super.platformStatus,
    super.cancelled,
    super.paidAt,
    super.unitPrice,
    super.lineAmount,
    super.discountAmount,
    super.platformDiscountAmount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] as num).toInt(),
      marketplaceAccountId: (json['marketplaceAccountId'] as num?)?.toInt() ?? 0,
      platform: json['platform'] as String? ?? '',
      externalOrderId: json['externalOrderId'] as String? ?? '',
      externalBoxId: json['externalBoxId'] as String?,
      externalItemId: json['externalItemId'] as String? ?? '',
      itemName: json['itemName'] as String?,
      ordererName: json['ordererName'] as String?,
      receiverName: json['receiverName'] as String?,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      cancelCount: (json['cancelCount'] as num?)?.toInt() ?? 0,
      holdCount: (json['holdCount'] as num?)?.toInt() ?? 0,
      purchasableQty: (json['purchasableQty'] as num?)?.toInt() ?? 0,
      // 모르는 상태값은 unknown 으로 접는다 — 앱이 서버보다 늦게 배포될 수 있다.
      status: orderStatusFrom(json['status'] as String?),
      platformStatus: json['platformStatus'] as String?,
      cancelled: json['cancelled'] as bool? ?? false,
      paidAt: json['paidAt'] as String?,
      // 금액은 서버가 BigDecimal 로 내려 소수점이 붙을 수 있다 — num 으로 받아 정수화한다.
      unitPrice: (json['unitPrice'] as num?)?.toInt(),
      lineAmount: (json['lineAmount'] as num?)?.toInt(),
      discountAmount: (json['discountAmount'] as num?)?.toInt(),
      platformDiscountAmount:
          (json['platformDiscountAmount'] as num?)?.toInt(),
    );
  }
}

class OrderSyncResultModel extends OrderSyncResult {
  const OrderSyncResultModel({
    required super.syncedAt,
    required super.newOrders,
    required super.updatedOrders,
    required super.canceledUpdated,
    required super.orders,
  });

  factory OrderSyncResultModel.fromJson(Map<String, dynamic> json) {
    return OrderSyncResultModel(
      syncedAt: json['syncedAt'] as String? ?? '',
      newOrders: (json['newOrders'] as num?)?.toInt() ?? 0,
      updatedOrders: (json['updatedOrders'] as num?)?.toInt() ?? 0,
      canceledUpdated: (json['canceledUpdated'] as num?)?.toInt() ?? 0,
      orders: (json['orders'] as List<dynamic>? ?? [])
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderMonthModel extends OrderMonth {
  const OrderMonthModel({required super.ym, required super.count});

  factory OrderMonthModel.fromJson(Map<String, dynamic> json) {
    return OrderMonthModel(
      ym: json['ym'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
