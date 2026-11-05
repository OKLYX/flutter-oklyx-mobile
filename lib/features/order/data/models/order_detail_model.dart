import 'package:flutter_oklyn_mobile/features/packing/domain/entities/packing.dart';

import '../../domain/entities/order_detail.dart';
import 'order_model.dart';

/// `OrderDetailResponse` → [OrderDetail] (FEATURE_2611_07 / PLAN D30). Both
/// order detail reads answer with this shape.
class OrderDetailModel extends OrderDetail {
  const OrderDetailModel({
    required super.externalOrderId,
    super.sellerName,
    super.platform,
    super.accountAlias,
    super.ordererName,
    super.receiverName,
    super.paidAt,
    super.lines,
    super.parcels,
    super.lineMasters,
    super.admin,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final lines = json['lines'];
    final parcels = json['parcels'];
    final lineMasters = json['lineMasters'];
    return OrderDetailModel(
      externalOrderId: json['externalOrderId'] as String? ?? '',
      sellerName: json['sellerName'] as String?,
      platform: json['platform'] as String?,
      accountAlias: json['accountAlias'] as String?,
      ordererName: json['ordererName'] as String?,
      receiverName: json['receiverName'] as String?,
      paidAt: json['paidAt'] as String?,
      lines: lines is List
          ? lines
              .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      parcels: parcels is List
          ? parcels.map((e) => _parcel(e as Map<String, dynamic>)).toList()
          : const [],
      lineMasters: lineMasters is List
          ? lineMasters
              .map((e) => _lineMaster(e as Map<String, dynamic>))
              .toList()
          : const [],
      // FEATURE_2611_15 / D20 — missing or not true = not an admin (no master
      // product link), the same reading as `dashboard_json.dart`.
      admin: json['admin'] == true,
    );
  }

  static OrderLineMaster _lineMaster(Map<String, dynamic> json) {
    final products = json['products'];
    return OrderLineMaster(
      orderLineId: (json['orderLineId'] as num).toInt(),
      masterProductId: (json['masterProductId'] as num?)?.toInt(),
      masterProductName: json['masterProductName'] as String?,
      masterOptionName: json['masterOptionName'] as String?,
      products: products is List
          ? products
              .map((e) => _lineProduct(e as Map<String, dynamic>))
              .toList()
          : const [],
      unexpandedReason: json['unexpandedReason'] as String?,
    );
  }

  static OrderLineProduct _lineProduct(Map<String, dynamic> json) =>
      OrderLineProduct(
        productId: (json['productId'] as num).toInt(),
        productName: json['productName'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );

  static OrderDetailParcel _parcel(Map<String, dynamic> json) {
    final items = json['items'];
    return OrderDetailParcel(
      parcelId: (json['parcelId'] as num).toInt(),
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      carrierName: json['carrierName'] as String?,
      parcelSeq: (json['parcelSeq'] as num?)?.toInt(),
      status: ParcelStatus.parse(json['status'] as String?),
      packedAt: json['packedAt'] as String?,
      boxName: json['boxName'] as String?,
      boxPackageId: (json['boxPackageId'] as num?)?.toInt(),
      items: items is List
          ? items.map((e) => _item(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  static OrderDetailParcelItem _item(Map<String, dynamic> json) =>
      OrderDetailParcelItem(
        productId: (json['productId'] as num).toInt(),
        productName: json['productName'] as String?,
        imageUrl: json['imageUrl'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );
}
