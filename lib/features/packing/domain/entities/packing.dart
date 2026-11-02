// Packing screen data (FEATURE_2611_03 / PLAN D10 · D23 · D27) — the same
// calls as the web `PackingEntity.ts`. Every judgement (remaining quantity,
// last box, full-quantity check) is the server's; the app only shows it.

/// A real box status. Only [pending] can be packed.
enum ParcelStatus {
  pending,
  packed,
  unused;

  /// `PENDING` · `PACKED` · `UNUSED` → the value. An unknown value is
  /// [packed] so the screen never offers to pack it.
  static ParcelStatus parse(String? raw) => switch (raw) {
        'PENDING' => ParcelStatus.pending,
        'UNUSED' => ParcelStatus.unused,
        _ => ParcelStatus.packed,
      };
}

/// The scanned box itself.
class PackingParcel {
  final int id;
  final String invoiceNumber;
  final String? carrierName;
  final int? parcelSeq;

  /// Boxes of the same shipment bundle (= labels issued).
  final int totalParcels;
  final ParcelStatus status;

  const PackingParcel({
    required this.id,
    required this.invoiceNumber,
    required this.carrierName,
    required this.parcelSeq,
    required this.totalParcels,
    required this.status,
  });
}

/// The order shown above the items. The screen picks receiver ?? orderer and
/// alias ?? platform.
class PackingOrder {
  final String externalOrderId;
  final String? sellerName;
  final String? ordererName;
  final String? receiverName;
  final String? platform;
  final String? accountAlias;

  const PackingOrder({
    required this.externalOrderId,
    required this.sellerName,
    required this.ordererName,
    required this.receiverName,
    required this.platform,
    required this.accountAlias,
  });
}

/// One thing to put in this box = (order line × product). A scan is matched
/// on the screen with [barcodeId]; the server is asked only when it fails.
class PackingRemainingItem {
  final int orderLineId;
  final String itemName;
  final int productId;
  final String productName;
  final String? barcodeId;
  final int remainingQty;
  final String? imageUrl;

  const PackingRemainingItem({
    required this.orderLineId,
    required this.itemName,
    required this.productId,
    required this.productName,
    required this.barcodeId,
    required this.remainingQty,
    required this.imageUrl,
  });
}

/// An order line that could not be expanded — the box cannot be completed.
class PackingUnexpanded {
  final int orderLineId;
  final String externalOrderId;
  final String itemName;
  final String reason;

  const PackingUnexpanded({
    required this.orderLineId,
    required this.externalOrderId,
    required this.itemName,
    required this.reason,
  });
}

/// `GET /api/admin/packing/scan` result.
class PackingScan {
  final PackingParcel parcel;
  final PackingOrder order;
  final List<PackingRemainingItem> remaining;
  final List<PackingUnexpanded> unexpanded;

  /// The server's 「last box」 judgement — true = every remaining item must go
  /// into this box.
  final bool isLastParcel;

  const PackingScan({
    required this.parcel,
    required this.order,
    required this.remaining,
    required this.unexpanded,
    required this.isLastParcel,
  });
}

/// One box of the work list — the server already keeps only PENDING boxes
/// with something left to pack.
class PendingParcel {
  final int parcelId;
  final String invoiceNumber;
  final String? carrierName;
  final int? parcelSeq;
  final int totalParcels;
  final String externalOrderId;
  final String? sellerName;
  final int remainingQty;
  final String? orderedAt;

  const PendingParcel({
    required this.parcelId,
    required this.invoiceNumber,
    required this.carrierName,
    required this.parcelSeq,
    required this.totalParcels,
    required this.externalOrderId,
    required this.sellerName,
    required this.remainingQty,
    required this.orderedAt,
  });
}

/// A barcode the screen could not match, asked to the server.
/// `found == false` = not registered · `inThisParcel == false` = not in this
/// order.
class BarcodeLookup {
  final bool found;
  final int? productId;
  final String? productName;
  final bool inThisParcel;

  const BarcodeLookup({
    required this.found,
    required this.productId,
    required this.productName,
    required this.inThisParcel,
  });
}

/// One recommended box for the composition (at most 3).
class BoxCandidate {
  final int packageId;
  final String type;
  final double widthCm;
  final double lengthCm;
  final double heightCm;
  final String? lastUsedAt;

  const BoxCandidate({
    required this.packageId,
    required this.type,
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
    required this.lastUsedAt,
  });
}

/// One product × quantity of the composition sent for box candidates.
class BoxCandidateItem {
  final int productId;
  final int quantity;

  const BoxCandidateItem({required this.productId, required this.quantity});
}

/// One packed line of [이 박스 완료].
class PackedItem {
  final int orderLineId;
  final int productId;
  final int quantity;

  const PackedItem({
    required this.orderLineId,
    required this.productId,
    required this.quantity,
  });
}

/// [이 박스 완료] result. [notices] = the borrowed-goods lines
/// (FEATURE_2610_19 D49).
class PackingCompleteResult {
  final int parcelId;
  final ParcelStatus status;
  final int packedQty;
  final List<String> notices;

  const PackingCompleteResult({
    required this.parcelId,
    required this.status,
    required this.packedQty,
    required this.notices,
  });
}

/// Result of closing a box as unused or restoring it.
class PackingCloseResult {
  final int parcelId;
  final ParcelStatus status;

  const PackingCloseResult({required this.parcelId, required this.status});
}
