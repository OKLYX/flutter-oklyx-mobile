/// A single purchase transaction recorded against a shopping list line.
///
/// `quantity` may be negative for corrections.
class PurchaseRecord {
  final int id;
  final String purchasedOn; // YYYY-MM-DD
  final int quantity;

  PurchaseRecord({
    required this.id,
    required this.purchasedOn,
    required this.quantity,
  });
}
