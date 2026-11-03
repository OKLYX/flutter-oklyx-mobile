import '../../domain/entities/packing.dart';
import '../../domain/entities/packing_history.dart';

/// JSON of the packing calls (FEATURE_2611_03 / PLAN D27 · D30) — the server
/// `PackingScanResponse` · `PendingParcelView` · `BarcodeLookupResponse` ·
/// `BoxCandidate` · `ParcelCompleteResponse` · `ParcelCloseResponse` ·
/// `PackingHistoryView`.

List<Map<String, dynamic>> _maps(dynamic raw) =>
    ((raw as List<dynamic>?) ?? const [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

class PackingScanModel extends PackingScan {
  const PackingScanModel({
    required super.parcel,
    required super.order,
    required super.remaining,
    required super.unexpanded,
    required super.isLastParcel,
  });

  factory PackingScanModel.fromJson(Map<String, dynamic> json) {
    final parcel = json['parcel'] as Map<String, dynamic>;
    final order = json['order'] as Map<String, dynamic>;
    return PackingScanModel(
      parcel: PackingParcel(
        id: parcel['id'] as int,
        invoiceNumber: parcel['invoiceNumber'] as String? ?? '',
        carrierName: parcel['carrierName'] as String?,
        parcelSeq: parcel['parcelSeq'] as int?,
        totalParcels: parcel['totalParcels'] as int? ?? 1,
        status: ParcelStatus.parse(parcel['status'] as String?),
      ),
      order: PackingOrder(
        externalOrderId: order['externalOrderId'] as String? ?? '',
        sellerName: order['sellerName'] as String?,
        ordererName: order['ordererName'] as String?,
        receiverName: order['receiverName'] as String?,
        platform: order['platform'] as String?,
        accountAlias: order['accountAlias'] as String?,
      ),
      remaining: _maps(json['remaining'])
          .map(
            (e) => PackingRemainingItem(
              orderLineId: e['orderLineId'] as int,
              itemName: e['itemName'] as String? ?? '',
              productId: e['productId'] as int,
              productName: e['productName'] as String? ?? '',
              barcodeId: e['barcodeId'] as String?,
              remainingQty: e['remainingQty'] as int? ?? 0,
              imageUrl: e['imageUrl'] as String?,
            ),
          )
          .toList(),
      unexpanded: _maps(json['unexpanded'])
          .map(
            (e) => PackingUnexpanded(
              orderLineId: e['orderLineId'] as int,
              externalOrderId: e['externalOrderId'] as String? ?? '',
              itemName: e['itemName'] as String? ?? '',
              reason: e['reason'] as String? ?? '',
            ),
          )
          .toList(),
      isLastParcel: json['isLastParcel'] as bool? ?? false,
    );
  }
}

class PendingParcelModel extends PendingParcel {
  const PendingParcelModel({
    required super.parcelId,
    required super.invoiceNumber,
    required super.carrierName,
    required super.parcelSeq,
    required super.totalParcels,
    required super.externalOrderId,
    required super.sellerName,
    required super.remainingQty,
    required super.orderedAt,
  });

  factory PendingParcelModel.fromJson(Map<String, dynamic> json) =>
      PendingParcelModel(
        parcelId: json['parcelId'] as int,
        invoiceNumber: json['invoiceNumber'] as String? ?? '',
        carrierName: json['carrierName'] as String?,
        parcelSeq: json['parcelSeq'] as int?,
        totalParcels: json['totalParcels'] as int? ?? 1,
        externalOrderId: json['externalOrderId'] as String? ?? '',
        sellerName: json['sellerName'] as String?,
        remainingQty: json['remainingQty'] as int? ?? 0,
        orderedAt: json['orderedAt'] as String?,
      );
}

class BarcodeLookupModel extends BarcodeLookup {
  const BarcodeLookupModel({
    required super.found,
    required super.productId,
    required super.productName,
    required super.inThisParcel,
  });

  factory BarcodeLookupModel.fromJson(Map<String, dynamic> json) =>
      BarcodeLookupModel(
        found: json['found'] as bool? ?? false,
        productId: json['productId'] as int?,
        productName: json['productName'] as String?,
        inThisParcel: json['inThisParcel'] as bool? ?? false,
      );
}

class BoxCandidateModel extends BoxCandidate {
  const BoxCandidateModel({
    required super.packageId,
    required super.type,
    required super.widthCm,
    required super.lengthCm,
    required super.heightCm,
    required super.lastUsedAt,
  });

  factory BoxCandidateModel.fromJson(Map<String, dynamic> json) =>
      BoxCandidateModel(
        packageId: json['packageId'] as int,
        type: json['type'] as String? ?? '',
        widthCm: (json['widthCm'] as num?)?.toDouble() ?? 0,
        lengthCm: (json['lengthCm'] as num?)?.toDouble() ?? 0,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
        lastUsedAt: json['lastUsedAt'] as String?,
      );
}

class PackingCompleteResultModel extends PackingCompleteResult {
  const PackingCompleteResultModel({
    required super.parcelId,
    required super.status,
    required super.packedQty,
    required super.notices,
  });

  factory PackingCompleteResultModel.fromJson(Map<String, dynamic> json) =>
      PackingCompleteResultModel(
        parcelId: json['parcelId'] as int,
        status: ParcelStatus.parse(json['status'] as String?),
        packedQty: json['packedQty'] as int? ?? 0,
        notices: ((json['notices'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

class PackingCloseResultModel extends PackingCloseResult {
  const PackingCloseResultModel({
    required super.parcelId,
    required super.status,
  });

  factory PackingCloseResultModel.fromJson(Map<String, dynamic> json) =>
      PackingCloseResultModel(
        parcelId: json['parcelId'] as int,
        status: ParcelStatus.parse(json['status'] as String?),
      );
}

class PackingHistoryEntryModel extends PackingHistoryEntry {
  const PackingHistoryEntryModel({
    required super.id,
    required super.changedAt,
    required super.parcelId,
    required super.invoiceNumber,
    required super.carrierName,
    required super.externalOrderId,
    required super.sellerName,
    required super.fromStatus,
    required super.toStatus,
    required super.changedBy,
    required super.boxName,
    required super.boxPackageId,
  });

  factory PackingHistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      PackingHistoryEntryModel(
        id: json['id'] as int,
        changedAt: json['changedAt'] as String? ?? '',
        parcelId: json['parcelId'] as int,
        invoiceNumber: json['invoiceNumber'] as String? ?? '',
        carrierName: json['carrierName'] as String?,
        externalOrderId: json['externalOrderId'] as String? ?? '',
        sellerName: json['sellerName'] as String?,
        fromStatus: ParcelStatus.parse(json['fromStatus'] as String?),
        toStatus: ParcelStatus.parse(json['toStatus'] as String?),
        changedBy: json['changedBy'] as String?,
        boxName: json['boxName'] as String?,
        boxPackageId: json['boxPackageId'] as int?,
      );
}
