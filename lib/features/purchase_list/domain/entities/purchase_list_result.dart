import 'purchase_list_item.dart';
import 'unmapped_order.dart';

/// Combined response of `GET /api/admin/purchase-list` and `/extract`:
/// the active product groups plus orders that could not be mapped.
class PurchaseListResult {
  final List<PurchaseListItem> items;
  final List<UnmappedOrder> unmappedOrders;

  PurchaseListResult({
    required this.items,
    required this.unmappedOrders,
  });
}
