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
  });

  /// 「판매처」 text (D35): 「{channel} · {alias}」, or only 「{channel}」 when
  /// the alias is blank.
  /// ⚠️ Not the packing screen's channel text (alias alone) — that one stays
  /// as it is (D35).
  String get salesChannel {
    final channel = platform == null ? '-' : platformName(platform!);
    final alias = accountAlias?.trim() ?? '';
    return alias.isEmpty ? channel : '$channel · $alias';
  }
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
