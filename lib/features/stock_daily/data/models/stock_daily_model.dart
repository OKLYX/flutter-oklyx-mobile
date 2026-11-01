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
    required super.productName,
    required super.quantity,
    required super.sellerName,
    required super.owners,
    required super.undecidedLeft,
    required super.orderNumber,
    required super.tags,
    required super.amount,
  });

  factory StockDailyRowModel.fromJson(Map<String, dynamic> json) =>
      StockDailyRowModel(
        movementId: json['movementId'] as int,
        movementType: json['movementType'] as String? ?? '',
        reason: json['reason'] as String?,
        productName: json['productName'] as String? ?? '',
        quantity: json['quantity'] as int,
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
      );
}
