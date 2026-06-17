import '../../domain/entities/order_item.dart';
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
    required super.orderCount,
    required super.cancelCount,
    required super.holdCount,
    required super.purchasableQty,
    required super.status,
    super.paidAt,
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
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      cancelCount: (json['cancelCount'] as num?)?.toInt() ?? 0,
      holdCount: (json['holdCount'] as num?)?.toInt() ?? 0,
      purchasableQty: (json['purchasableQty'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      paidAt: json['paidAt'] as String?,
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
