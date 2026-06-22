/// An order line that cannot be expanded into components because its option
/// is not mapped (or its BOM is empty). Surfaced so the user can register the
/// missing option.
class UnmappedOrder {
  final String externalItemId;
  final String itemName;
  final int purchasableQty;
  final int orderCount;

  UnmappedOrder({
    required this.externalItemId,
    required this.itemName,
    required this.purchasableQty,
    required this.orderCount,
  });
}
