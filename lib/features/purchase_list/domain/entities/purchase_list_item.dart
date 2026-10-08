import 'purchase_line.dart';

/// A product group on the purchase list, aggregating all its lines.
class PurchaseListItem {
  final int productId;
  final String productName;

  /// Product brand; null when the product has none (or an older server).
  final String? brand;
  final int neededQty;
  final int purchasedQty;
  final int remainingQty;
  final List<PurchaseLine> lines;

  PurchaseListItem({
    required this.productId,
    required this.productName,
    required this.neededQty,
    required this.purchasedQty,
    required this.remainingQty,
    required this.lines,
    this.brand,
  });
}
