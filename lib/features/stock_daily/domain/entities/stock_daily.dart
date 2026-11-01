/// 「일별 입출고 내역」 (FEATURE_2610_19 D119 · D123 · D124 · D128 · D130 ·
/// D147). An `amount` of null is 「미기입」, never drawn as 0.
class StockDaily {
  final String date;

  /// 「영수증 미등록 N건」 (D147); 0 = the line is hidden.
  final int unregisteredProductCount;
  final List<UnregisteredProduct> unregistered;
  final List<StockDailyRow> rows;

  const StockDaily({
    required this.date,
    required this.unregisteredProductCount,
    required this.unregistered,
    required this.rows,
  });
}

/// One product of the day a receipt can still be assigned to (D121 ①).
class UnregisteredProduct {
  final int productId;
  final String productName;
  final int remainingQty;

  const UnregisteredProduct({
    required this.productId,
    required this.productName,
    required this.remainingQty,
  });
}

/// One ledger row of the day.
class StockDailyRow {
  final int movementId;
  final String movementType;
  final String? reason;
  final String productName;
  final int quantity;
  final String? sellerName;
  final List<String> owners;
  final int? undecidedLeft;
  final String? orderNumber;
  final List<String> tags;
  final double? amount;

  const StockDailyRow({
    required this.movementId,
    required this.movementType,
    required this.reason,
    required this.productName,
    required this.quantity,
    required this.sellerName,
    required this.owners,
    required this.undecidedLeft,
    required this.orderNumber,
    required this.tags,
    required this.amount,
  });
}
