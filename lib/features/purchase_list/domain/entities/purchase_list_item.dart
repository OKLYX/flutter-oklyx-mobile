import 'purchase_line.dart';

/// A product group on the purchase list, aggregating all its lines.
class PurchaseListItem {
  final int productId;
  final String productName;
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
  });
}
