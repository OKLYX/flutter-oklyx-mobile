/// One line of a receipt. [totalAmount]/[unitPrice] null = amount not entered
/// (FEATURE_2610_18 D41 · D68 「미기입」).
class ReceiptLine {
  final String productName;
  final int quantity;
  final double? totalAmount;
  final double? unitPrice;
  final bool reflectToBasePrice;

  const ReceiptLine({
    required this.productName,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    required this.reflectToBasePrice,
  });
}

/// One receipt with its photo and lines (FEATURE_2610_18 D93 ①).
///
/// [photoUrl] = the stored value: an `http` URL on dev/prod, a server disk
/// path on local (not viewable on the phone). [cardId] / [cardAlias] null =
/// the card was unknown (「카드 없음」). [payerSellerId] · [cardId] ·
/// [cardMaskedNumber] start the header edit (D100); a hidden card keeps its
/// alias and number here (D91 · D100 ⑥).
class ReceiptDetail {
  final int id;
  final String purchasedOn; // YYYY-MM-DD
  final int payerSellerId;
  final String payerSellerName;
  final int? cardId;
  final String? cardAlias;
  final String? cardMaskedNumber;
  final String photoUrl;
  final List<ReceiptLine> lines;

  const ReceiptDetail({
    required this.id,
    required this.purchasedOn,
    required this.payerSellerId,
    required this.payerSellerName,
    this.cardId,
    this.cardAlias,
    this.cardMaskedNumber,
    required this.photoUrl,
    required this.lines,
  });
}
