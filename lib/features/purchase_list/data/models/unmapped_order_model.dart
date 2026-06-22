import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/unmapped_order.dart';

class UnmappedOrderModel extends UnmappedOrder {
  UnmappedOrderModel({
    required String externalItemId,
    required String itemName,
    required int purchasableQty,
    required int orderCount,
  }) : super(
          externalItemId: externalItemId,
          itemName: itemName,
          purchasableQty: purchasableQty,
          orderCount: orderCount,
        );

  factory UnmappedOrderModel.fromJson(Map<String, dynamic> json) {
    return UnmappedOrderModel(
      externalItemId: json['externalItemId'] as String,
      itemName: json['itemName'] as String? ?? '',
      purchasableQty: json['purchasableQty'] as int,
      orderCount: json['orderCount'] as int,
    );
  }
}
