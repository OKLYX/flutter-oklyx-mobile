import 'purchase_record.dart';

/// One line of the purchase list: either an order-derived line (source "ORDER")
/// or a user-added manual line (source "MANUAL", [orderItemId] null).
class PurchaseLine {
  final int itemId;
  final int? orderItemId;
  final String source; // "ORDER" | "MANUAL"
  final String? externalOrderId;
  final int autoQty;
  final int manualQty;
  final int purchasedQty;
  final List<PurchaseRecord> records;

  PurchaseLine({
    required this.itemId,
    required this.orderItemId,
    required this.source,
    required this.externalOrderId,
    required this.autoQty,
    required this.manualQty,
    required this.purchasedQty,
    required this.records,
  });

  bool get isManual => source == 'MANUAL';

  int get neededQty => autoQty + manualQty;
}
