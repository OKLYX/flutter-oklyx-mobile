import 'purchase_list_item.dart';
import 'unmapped_order.dart';

/// Combined response of `GET /api/admin/purchase-list` and `/extract`:
/// the rows to buy, the 「오늘 넘김」 rows (FEATURE_2610_09 D67) and the orders
/// that could not be mapped.
class PurchaseListResult {
  final List<PurchaseListItem> items;
  final List<PurchaseListItem> skippedToday;
  final List<UnmappedOrder> unmappedOrders;

  PurchaseListResult({
    required this.items,
    required this.skippedToday,
    required this.unmappedOrders,
  });
}
