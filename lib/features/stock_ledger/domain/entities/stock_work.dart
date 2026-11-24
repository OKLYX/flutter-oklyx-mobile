import 'stock_enums.dart';

/// FEATURE_2611_34 stock work request lines.
///
/// One line sent by the 「출고 작업」 save (`POST /api/admin/stock/
/// outbound-work`). [quantity] is positive — the server flips the sign.
/// [reasonNote] is set only for [StockReason.etc] (R25).
class OutboundWorkLineRequest {
  final int productId;
  final int sellerId;
  final StockReason reason;
  final String? reasonNote;
  final int quantity;

  const OutboundWorkLineRequest({
    required this.productId,
    required this.sellerId,
    required this.reason,
    required this.quantity,
    this.reasonNote,
  });
}

/// Which claim work a [ClaimWork] screen does (FEATURE_2611_34 D1 · D38).
enum ClaimWorkKind { returnIntake, exchangeShip }

/// Key of one (claim × product) quantity field (FEATURE_2611_34 D20).
String claimItemKey(int orderClaimId, int productId) =>
    '$orderClaimId:$productId';

/// One product of a [ClaimWork] — to take back or to send (PLAN §3-4).
///
/// The picture is drawn by `ProductThumbnail(productId: …)`; the server's
/// image url is not read (2611_33 D8).
class ClaimWorkItem {
  final int productId;
  final String productName;
  final String? barcode;
  final int requiredQty;
  final int doneQty;
  final int remainingQty;

  const ClaimWorkItem({
    required this.productId,
    required this.productName,
    required this.requiredQty,
    required this.doneQty,
    required this.remainingQty,
    this.barcode,
  });
}

/// One return / exchange claim found by a claim work lookup (PLAN §3-4).
///
/// [failure] is set (and [items] empty) when its products are unknown (R7).
class ClaimWork {
  final int orderClaimId;
  final String claimType;
  final String externalOrderId;
  final String platform;
  final String? accountAlias;
  final String? sellerName;
  final String? requesterName;
  final String claimStatus;
  final String? collectStatus;
  final String? itemName;
  final int claimQty;
  final String receivedAt;
  final String? failure;
  final List<ClaimWorkItem> items;

  const ClaimWork({
    required this.orderClaimId,
    required this.claimType,
    required this.externalOrderId,
    required this.platform,
    required this.claimStatus,
    required this.claimQty,
    required this.receivedAt,
    required this.items,
    this.accountAlias,
    this.sellerName,
    this.requesterName,
    this.collectStatus,
    this.itemName,
    this.failure,
  });
}

/// One recently shipped order of 「송장 없이 반품 완료」 (PLAN §3-5).
class ShippedOrder {
  final int orderId;
  final String externalOrderId;
  final String? orderedAt;
  final String platform;
  final String? accountAlias;
  final String? sellerName;
  final String? itemName;

  /// A return / exchange of this order is still open (R8).
  final bool claimPending;

  const ShippedOrder({
    required this.orderId,
    required this.externalOrderId,
    required this.platform,
    required this.claimPending,
    this.orderedAt,
    this.accountAlias,
    this.sellerName,
    this.itemName,
  });
}

/// One line sent by the 「반품 재입고」 / 「교환 발송」 save (PLAN §3-3).
class ClaimWorkLineRequest {
  final int orderClaimId;
  final int productId;
  final int quantity;

  const ClaimWorkLineRequest({
    required this.orderClaimId,
    required this.productId,
    required this.quantity,
  });
}
