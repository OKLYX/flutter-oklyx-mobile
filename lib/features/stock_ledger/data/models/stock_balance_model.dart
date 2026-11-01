import '../../domain/entities/stock_balance.dart';

class StockBalanceModel extends StockBalance {
  const StockBalanceModel({
    required super.productId,
    required super.productName,
    required super.sellerId,
    required super.sellerName,
    required super.onHand,
    super.amount,
  });

  factory StockBalanceModel.fromJson(Map<String, dynamic> json) {
    return StockBalanceModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      sellerId: json['sellerId'] as int? ?? 0,
      // FEATURE_2610_19 D116 ② · D124: no seller = an undecided intake row or a
      // row that used one.
      sellerName: json['sellerName'] as String? ?? '판매자 미정',
      // 음수 그대로 싣는다 — 0 으로 깎으면 빠진 입고가 눈에 안 띈다.
      onHand: (json['onHand'] as num).toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}
