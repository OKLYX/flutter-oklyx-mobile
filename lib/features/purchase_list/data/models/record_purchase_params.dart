class RecordPurchaseParams {
  final String purchasedOn; // YYYY-MM-DD
  final int quantity; // negative allowed for corrections
  final double? totalAmount; // total mode only
  final double? unitPrice; // unit mode only
  final bool reflectToBasePrice;

  RecordPurchaseParams({
    required this.purchasedOn,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
  });

  Map<String, dynamic> toJson() => {
        'purchasedOn': purchasedOn,
        'quantity': quantity,
        // Send exactly one of the two, and omit the key entirely when unknown —
        // the server rejects both-present with 400, and a null amount would be
        // read as "no amount" anyway (PLAN 2609_28 D1).
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (unitPrice != null) 'unitPrice': unitPrice,
        'reflectToBasePrice': reflectToBasePrice,
      };
}
