import '../../domain/entities/stock_work.dart';

int _int(Map<String, dynamic> json, String key) =>
    (json[key] as num?)?.toInt() ?? 0;

/// One claim of the claim work lookups (FEATURE_2611_34 PLAN §3-4).
///
/// `items[].imageUrl` is not read — `ProductThumbnail` draws the picture.
class ClaimWorkModel extends ClaimWork {
  const ClaimWorkModel({
    required super.orderClaimId,
    required super.claimType,
    required super.externalOrderId,
    required super.platform,
    required super.claimStatus,
    required super.claimQty,
    required super.receivedAt,
    required super.items,
    super.accountAlias,
    super.sellerName,
    super.requesterName,
    super.collectStatus,
    super.itemName,
    super.failure,
  });

  factory ClaimWorkModel.fromJson(Map<String, dynamic> json) =>
      ClaimWorkModel(
        orderClaimId: _int(json, 'orderClaimId'),
        claimType: json['claimType'] as String? ?? '',
        externalOrderId: json['externalOrderId'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        accountAlias: json['accountAlias'] as String?,
        sellerName: json['sellerName'] as String?,
        requesterName: json['requesterName'] as String?,
        claimStatus: json['claimStatus'] as String? ?? '',
        collectStatus: json['collectStatus'] as String?,
        itemName: json['itemName'] as String?,
        claimQty: _int(json, 'claimQty'),
        receivedAt: json['receivedAt'] as String? ?? '',
        failure: json['failure'] as String?,
        items: [
          for (final e in (json['items'] as List<dynamic>?) ?? const [])
            _item(e as Map<String, dynamic>),
        ],
      );

  static ClaimWorkItem _item(Map<String, dynamic> json) => ClaimWorkItem(
        productId: _int(json, 'productId'),
        productName: json['productName'] as String? ?? '',
        barcode: json['barcode'] as String?,
        requiredQty: _int(json, 'requiredQty'),
        doneQty: _int(json, 'doneQty'),
        remainingQty: _int(json, 'remainingQty'),
      );
}

/// One order of `GET …/return-work/shipped-orders` (PLAN §3-5).
class ShippedOrderModel extends ShippedOrder {
  const ShippedOrderModel({
    required super.orderId,
    required super.externalOrderId,
    required super.platform,
    required super.claimPending,
    super.orderedAt,
    super.accountAlias,
    super.sellerName,
    super.itemName,
  });

  factory ShippedOrderModel.fromJson(Map<String, dynamic> json) =>
      ShippedOrderModel(
        orderId: _int(json, 'orderId'),
        externalOrderId: json['externalOrderId'] as String? ?? '',
        orderedAt: json['orderedAt'] as String?,
        platform: json['platform'] as String? ?? '',
        accountAlias: json['accountAlias'] as String?,
        sellerName: json['sellerName'] as String?,
        itemName: json['itemName'] as String?,
        claimPending: json['claimPending'] as bool? ?? false,
      );
}
