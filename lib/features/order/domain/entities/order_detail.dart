import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/packing/domain/entities/packing.dart';

import 'order_item.dart';

/// One order for the shared order detail (FEATURE_2611_07 / PLAN D17 · D30) —
/// 1:1 with the backend `OrderDetailResponse`.
///
/// The same shape comes from both reads: by the tapped order line (「주문내역」)
/// and by the tapped parcel (「포장 작업」 「오늘 완료」). No phone, postcode or
/// address (D22).
class OrderDetail {
  final String externalOrderId;
  final String? sellerName;

  /// Sales channel (`Platform` name, e.g. `COUPANG`).
  final String? platform;
  final String? accountAlias;
  final String? ordererName;
  final String? receiverName;
  final String? paidAt;

  /// Every line of the order, id order — each the same fields as one order
  /// list row.
  final List<OrderItem> lines;

  /// Every parcel of the order — bundle order, then parcel sequence (D29);
  /// empty = no invoice yet (D26).
  final List<OrderDetailParcel> parcels;

  /// Where each line comes from — one per line, the order of [lines]
  /// (FEATURE_2611_15 / D1 · D3 · D5).
  final List<OrderLineMaster> lineMasters;

  /// true = the viewer is an ADMIN — draw the master product link only then
  /// (FEATURE_2611_15 / D8 · D20). The server decides it; the app has no role.
  final bool admin;

  const OrderDetail({
    required this.externalOrderId,
    this.sellerName,
    this.platform,
    this.accountAlias,
    this.ordererName,
    this.receiverName,
    this.paidAt,
    this.lines = const [],
    this.parcels = const [],
    this.lineMasters = const [],
    this.admin = false,
  });

  /// The [OrderLineMaster] of the line, null when the server sent none.
  OrderLineMaster? lineMasterOf(int orderLineId) {
    for (final master in lineMasters) {
      if (master.orderLineId == orderLineId) {
        return master;
      }
    }
    return null;
  }

  /// 「판매처」 text (D35) — built by [salesChannelLabel] only (FEATURE_2611_24 / D15).
  /// ⚠️ Not the packing screen's channel text (alias alone) — that one stays
  /// as it is (D35).
  String get salesChannel => salesChannelLabel(platform, accountAlias);
}

/// One parcel (invoice) of the order (D23 · D36 · D37).
class OrderDetailParcel {
  final int parcelId;
  final String invoiceNumber;
  final String? carrierName;
  final int? parcelSeq;
  final ParcelStatus status;

  /// Processed time as a KST wall clock (D38) — null for 「작업 전」.
  final String? packedAt;

  /// Only for 「포장 완료」, otherwise null (D37).
  final String? boxName;
  final int? boxPackageId;

  /// Only for 「포장 완료」, otherwise empty (D37) — merged per product.
  final List<OrderDetailParcelItem> items;

  const OrderDetailParcel({
    required this.parcelId,
    required this.invoiceNumber,
    required this.status,
    this.carrierName,
    this.parcelSeq,
    this.packedAt,
    this.boxName,
    this.boxPackageId,
    this.items = const [],
  });

  /// Status words of the chips (D25 · D29).
  String get statusLabel => switch (status) {
        ParcelStatus.pending => '작업 전',
        ParcelStatus.packed => '포장 완료',
        ParcelStatus.unused => '미사용',
      };

  /// Chip text = the whole invoice number + the status, e.g.
  /// 「123456789012 · 포장 완료」 (D29).
  String get chipLabel => '$invoiceNumber · $statusLabel';
}

/// One packed product — draw its photo with `ProductThumbnail(productId:)`.
class OrderDetailParcelItem {
  final int productId;
  final String? productName;
  final String? imageUrl;
  final int quantity;

  const OrderDetailParcelItem({
    required this.productId,
    required this.quantity,
    this.productName,
    this.imageUrl,
  });
}

/// The master product, master option and component products of one order
/// line (FEATURE_2611_15 / D1 · D3 · D5). [unexpandedReason] null = linked;
/// otherwise the broken link's code — show `unexpandedReasonLabel(code)` only.
class OrderLineMaster {
  final int orderLineId;
  final int? masterProductId;
  final String? masterProductName;
  final String? masterOptionName;

  /// BOM order — empty when [unexpandedReason] is set.
  final List<OrderLineProduct> products;

  /// `UNMAPPED_OPTION` · `NO_MASTER_OPTION` · `EMPTY_BOM`, null = linked.
  final String? unexpandedReason;

  const OrderLineMaster({
    required this.orderLineId,
    this.masterProductId,
    this.masterProductName,
    this.masterOptionName,
    this.products = const [],
    this.unexpandedReason,
  });
}

/// One component product: quantity = per-set quantity × the line's
/// purchasable quantity (FEATURE_2611_15 / D4 · D18). Draw its photo with
/// the order detail page's `_Thumb` (`ProductThumbnail`).
class OrderLineProduct {
  final int productId;
  final String productName;
  final String? imageUrl;
  final int quantity;

  const OrderLineProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.imageUrl,
  });
}
