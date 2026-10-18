import '../../domain/entities/receipt_detail.dart';

class ReceiptDetailModel extends ReceiptDetail {
  const ReceiptDetailModel({
    required super.id,
    required super.purchasedOn,
    required super.payerSellerId,
    required super.payerSellerName,
    super.cardId,
    super.cardAlias,
    super.cardMaskedNumber,
    required super.photoUrl,
    required super.lines,
  });

  factory ReceiptDetailModel.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List<dynamic>?) ?? const [];
    return ReceiptDetailModel(
      id: json['id'] as int,
      purchasedOn: json['purchasedOn'] as String,
      payerSellerId: json['payerSellerId'] as int,
      payerSellerName: json['payerSellerName'] as String? ?? '',
      cardId: json['cardId'] as int?,
      cardAlias: json['cardAlias'] as String?,
      cardMaskedNumber: json['cardMaskedNumber'] as String?,
      photoUrl: json['photoUrl'] as String? ?? '',
      lines: lines.map((e) {
        final line = e as Map<String, dynamic>;
        return ReceiptLine(
          productName: line['productName'] as String? ?? '',
          quantity: line['quantity'] as int,
          // ⚠️ Do NOT default to 0 — null is "amount not entered" (D41).
          totalAmount: (line['totalAmount'] as num?)?.toDouble(),
          unitPrice: (line['unitPrice'] as num?)?.toDouble(),
          reflectToBasePrice: line['reflectToBasePrice'] as bool? ?? true,
        );
      }).toList(),
    );
  }
}
