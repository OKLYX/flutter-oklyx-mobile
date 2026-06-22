import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';

abstract class PurchaseListRepository {
  /// Active purchase list (items with remainingQty > 0) for an optional seller.
  Future<Either<Failure, List<PurchaseListItem>>> getList(int? sellerId);

  /// Re-extract the list from ACCEPT orders (idempotent); returns the refreshed list.
  Future<Either<Failure, List<PurchaseListItem>>> extract(int? sellerId);

  /// Record a purchase against a line. [quantity] may be negative for corrections.
  Future<Either<Failure, void>> recordPurchase(
    int itemId,
    String purchasedOn,
    int quantity,
  );

  /// Replace the manual quantity of a line with an absolute value (0+).
  Future<Either<Failure, void>> adjustManualQty(int itemId, int manualQty);
}
