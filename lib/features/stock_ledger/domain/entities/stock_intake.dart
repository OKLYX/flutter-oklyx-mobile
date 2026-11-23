import 'stock_enums.dart';

/// Barcode lookup of the 「입고 작업」 screen (FEATURE_2611_33 D5 · D8).
///
/// Only the three values the app reads — no photo, no price (D8).
class IntakeBarcodeResult {
  final bool found;
  final int? productId;
  final String? productName;

  const IntakeBarcodeResult({
    required this.found,
    this.productId,
    this.productName,
  });
}

/// One line sent by [입고 저장] (FEATURE_2611_33 D4 ⑧).
///
/// [sellerId] null = 「미정」 (the key is left out of the request).
class StockIntakeLine {
  final int productId;
  final int quantity;
  final int? sellerId;
  final StockReason reason;

  const StockIntakeLine({
    required this.productId,
    required this.quantity,
    required this.reason,
    this.sellerId,
  });
}
