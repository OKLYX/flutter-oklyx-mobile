import '../../domain/entities/stock_balance.dart';

class StockBalanceModel extends StockBalance {
  const StockBalanceModel({
    required super.productId,
    required super.productName,
    required super.sellerId,
    required super.sellerName,
    required super.onHand,
  });

  factory StockBalanceModel.fromJson(Map<String, dynamic> json) {
    return StockBalanceModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      sellerId: json['sellerId'] as int? ?? 0,
      sellerName: json['sellerName'] as String? ?? '',
      // 음수 그대로 싣는다 — 0 으로 깎으면 빠진 입고가 눈에 안 띈다.
      onHand: (json['onHand'] as num).toInt(),
    );
  }
}
