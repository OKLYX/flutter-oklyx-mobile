import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_line.dart';

class PurchaseLineModel extends PurchaseLine {
  PurchaseLineModel({
    required int itemId,
    required int? orderItemId,
    required String source,
    required String? externalOrderId,
    int? marketplaceAccountId,
    required int sellerId,
    required String sellerName,
    String? platform,
    required int autoQty,
    required int manualQty,
  }) : super(
          itemId: itemId,
          orderItemId: orderItemId,
          source: source,
          externalOrderId: externalOrderId,
          marketplaceAccountId: marketplaceAccountId,
          sellerId: sellerId,
          sellerName: sellerName,
          platform: platform,
          autoQty: autoQty,
          manualQty: manualQty,
        );

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseLineModel(
      itemId: json['itemId'] as int,
      orderItemId: json['orderItemId'] as int?,
      source: json['source'] as String,
      externalOrderId: json['externalOrderId'] as String?,
      // A manual line has no account and no platform; both kinds carry the
      // seller (FEATURE_2610_09 D17).
      marketplaceAccountId: json['marketplaceAccountId'] as int?,
      sellerId: json['sellerId'] as int,
      sellerName: json['sellerName'] as String,
      platform: json['platform'] as String?,
      autoQty: json['autoQty'] as int,
      manualQty: json['manualQty'] as int,
    );
  }
}
