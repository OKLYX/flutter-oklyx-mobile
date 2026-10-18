import 'purchase_line.dart';
import 'purchase_share.dart';

/// A product row on the purchase list with its seller shares and the lines the
/// server sent (a chosen seller gets that seller's lines only — FEATURE_2610_09
/// D6).
class PurchaseListItem {
  final int productId;
  final String productName;

  /// Product brand; null when the product has none (or an older server).
  final String? brand;
  final int neededQty;
  final int purchasedQty;
  final int remainingQty;

  /// Seller chosen: that one share. 「전체」: every shown share, seller id
  /// ascending (FEATURE_2610_09 D59).
  final List<PurchaseShare> shares;
  final List<PurchaseLine> lines;

  PurchaseListItem({
    required this.productId,
    required this.productName,
    required this.neededQty,
    required this.purchasedQty,
    required this.remainingQty,
    required this.shares,
    required this.lines,
    this.brand,
  });
}
