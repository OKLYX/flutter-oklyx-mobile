/// Receipt header edit (FEATURE_2610_18 D100) — purchase day, card, payer
/// seller. The photo and the lines never change.
///
/// Same card rule as `CreateReceiptParams`: [cardId] set → the card owner pays;
/// [cardId] null (「카드로 알 수 없음」) → [payerSellerId] is required.
class UpdateReceiptParams {
  final String purchasedOn; // YYYY-MM-DD
  final int? cardId;
  final int? payerSellerId;

  const UpdateReceiptParams({
    required this.purchasedOn,
    this.cardId,
    this.payerSellerId,
  });

  Map<String, dynamic> toJson() => {
        'purchasedOn': purchasedOn,
        if (cardId != null) 'cardId': cardId,
        if (payerSellerId != null) 'payerSellerId': payerSellerId,
      };
}
