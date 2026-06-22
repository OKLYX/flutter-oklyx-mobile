class RecordPurchaseParams {
  final String purchasedOn; // YYYY-MM-DD
  final int quantity; // negative allowed for corrections

  RecordPurchaseParams({
    required this.purchasedOn,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'purchasedOn': purchasedOn,
        'quantity': quantity,
      };
}
