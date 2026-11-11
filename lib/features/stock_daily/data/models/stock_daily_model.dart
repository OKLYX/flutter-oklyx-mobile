import '../../domain/entities/stock_daily.dart';

/// The server `StockDailyView` (FEATURE_2610_19 D119 · D123 · D147).
class StockDailyModel extends StockDaily {
  const StockDailyModel({
    required super.date,
    required super.unregisteredProductCount,
    required super.unregistered,
    required super.rows,
  });

  factory StockDailyModel.fromJson(Map<String, dynamic> json) =>
      StockDailyModel(
        date: json['date'] as String? ?? '',
        unregisteredProductCount: json['unregisteredProductCount'] as int? ?? 0,
        unregistered: ((json['unregistered'] as List<dynamic>?) ?? const [])
            .map(
              (e) => UnregisteredProductModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
        rows: ((json['rows'] as List<dynamic>?) ?? const [])
            .map((e) => StockDailyRowModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One product of the day a receipt can still be assigned to (D121 ①).
class UnregisteredProductModel extends UnregisteredProduct {
  const UnregisteredProductModel({
    required super.productId,
    required super.productName,
    required super.remainingQty,
  });

  factory UnregisteredProductModel.fromJson(Map<String, dynamic> json) =>
      UnregisteredProductModel(
        productId: json['productId'] as int,
        productName: json['productName'] as String? ?? '',
        remainingQty: json['remainingQty'] as int? ?? 0,
      );
}

/// One ledger row of the day (`StockDailyRowView`).
class StockDailyRowModel extends StockDailyRow {
  const StockDailyRowModel({
    required super.movementId,
    required super.movementType,
    required super.reason,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.sellerId,
    required super.sellerName,
    required super.owners,
    required super.undecidedLeft,
    required super.orderNumber,
    required super.tags,
    required super.amount,
    required super.sellerChangeable,
    required super.recordId,
    required super.receiptKind,
    required super.receiptId,
    required super.shares,
    required super.unitPrices,
    required super.priceFromBase,
    required super.openingPriceEditable,
    required super.sourceMovementId,
    required super.sourceMovedOn,
    required super.sourcePriceEditable,
    required super.dateEdits,
    required super.fillable,
    required super.filledLater,
  });

  factory StockDailyRowModel.fromJson(Map<String, dynamic> json) =>
      StockDailyRowModel(
        movementId: json['movementId'] as int,
        movementType: json['movementType'] as String? ?? '',
        reason: json['reason'] as String?,
        productId: json['productId'] as int,
        productName: json['productName'] as String? ?? '',
        quantity: json['quantity'] as int,
        sellerId: json['sellerId'] as int?,
        sellerName: json['sellerName'] as String?,
        owners: ((json['owners'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
        undecidedLeft: json['undecidedLeft'] as int?,
        orderNumber: json['orderNumber'] as String?,
        tags: ((json['tags'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
        amount: (json['amount'] as num?)?.toDouble(),
        sellerChangeable: json['sellerChangeable'] as bool? ?? false,
        recordId: json['recordId'] as int?,
        receiptKind: ReceiptKind.fromCode(json['receiptKind'] as String?),
        receiptId: json['receiptId'] as int?,
        // FEATURE_2611_16 D8: every share of an undecided intake row.
        shares: ((json['shares'] as List<dynamic>?) ?? const []).map((e) {
          final share = e as Map<String, dynamic>;
          return StockDailyShare(
            recordId: share['recordId'] as int,
            sellerId: share['sellerId'] as int,
            sellerName: share['sellerName'] as String? ?? '',
            quantity: share['quantity'] as int,
            amount: (share['amount'] as num?)?.toDouble(),
            receiptKind:
                ReceiptKind.fromCode(share['receiptKind'] as String?) ??
                    ReceiptKind.noReceipt,
            receiptId: share['receiptId'] as int?,
            sellerChangeable: share['sellerChangeable'] as bool? ?? false,
            unitPrice: (share['unitPrice'] as num?)?.toDouble(),
            priceFromBase: share['priceFromBase'] as bool? ?? false,
          );
        }).toList(),
        // FEATURE_2611_17 D16 · D22 · D17: the unit prices, the 「미기입」 mark
        // and the opening-stock or 「기타」 price target (FEATURE_2611_22 D38).
        unitPrices: (json['unitPrices'] as List<dynamic>?)?.map((e) {
          final unit = e as Map<String, dynamic>;
          return UnitCount(
            unitPrice: (unit['unitPrice'] as num).toDouble(),
            quantity: unit['quantity'] as int,
          );
        }).toList(),
        priceFromBase: json['priceFromBase'] as bool? ?? false,
        openingPriceEditable: json['openingPriceEditable'] as bool? ?? false,
        // FEATURE_2611_21 D20 · D22 · D24: the lot of an outgoing row and the
        // row's day corrections.
        sourceMovementId: json['sourceMovementId'] as int?,
        sourceMovedOn: json['sourceMovedOn'] as String?,
        sourcePriceEditable: json['sourcePriceEditable'] as bool? ?? false,
        dateEdits: ((json['dateEdits'] as List<dynamic>?) ?? const []).map((e) {
          final edit = e as Map<String, dynamic>;
          return StockDateEdit(
            editedAt: edit['editedAt'] as String? ?? '',
            editedBy: edit['editedBy'] as String?,
            oldMovedOn: edit['oldMovedOn'] as String? ?? '',
            newMovedOn: edit['newMovedOn'] as String? ?? '',
          );
        }).toList(),
        // FEATURE_2611_22 D3 ② · D9: [입고로 채우기] and 「… 입고로 나중에 채움」.
        fillable: json['fillable'] as bool? ?? false,
        filledLater: json['filledLater'] as bool? ?? false,
      );
}

/// One receipt of the receipt list (`ReceiptSummaryView`, FEATURE_2610_18
/// D94) — the row sheet's receipt choices (FEATURE_2611_17 D23).
class DayReceiptModel extends DayReceipt {
  const DayReceiptModel({
    required super.id,
    required super.payerSellerId,
    required super.payerSellerName,
    required super.cardAlias,
    required super.firstProductName,
    required super.productCount,
    required super.hasPhoto,
  });

  factory DayReceiptModel.fromJson(Map<String, dynamic> json) =>
      DayReceiptModel(
        id: json['id'] as int,
        payerSellerId: json['payerSellerId'] as int,
        payerSellerName: json['payerSellerName'] as String? ?? '',
        cardAlias: json['cardAlias'] as String?,
        firstProductName: json['firstProductName'] as String?,
        productCount: json['productCount'] as int? ?? 0,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
      );
}
