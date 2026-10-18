/// One product line of a receipt check-in (FEATURE_2610_18 D76 · D96 · D97).
///
/// No seller — every line belongs to the payer seller (D89). [quantity] >= 1.
class ReceiptLineParams {
  final int productId;
  final String productName; // shown in the popup only, not sent
  final int quantity;
  final double? totalAmount; // total mode only
  final double? unitPrice; // unit mode only
  final bool reflectToBasePrice;

  const ReceiptLineParams({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        // Send at most one amount and omit the key when blank (PLAN 2609_28
        // D1 · D41).
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (unitPrice != null) 'unitPrice': unitPrice,
        'reflectToBasePrice': reflectToBasePrice,
      };
}

/// The JSON part of a receipt check-in (FEATURE_2610_18 D87).
///
/// [cardId] set → the card owner pays; [cardId] null → [payerSellerId] is
/// required (「카드로 알 수 없음」 or one seller).
class CreateReceiptParams {
  final String purchasedOn; // YYYY-MM-DD
  final int? cardId;
  final int? payerSellerId;
  final List<ReceiptLineParams> lines;

  const CreateReceiptParams({
    required this.purchasedOn,
    this.cardId,
    this.payerSellerId,
    required this.lines,
  });

  Map<String, dynamic> toJson() => {
        'purchasedOn': purchasedOn,
        if (cardId != null) 'cardId': cardId,
        if (payerSellerId != null) 'payerSellerId': payerSellerId,
        'lines': lines.map((line) => line.toJson()).toList(),
      };
}
