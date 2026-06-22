import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';
import '../entities/purchase_list_result.dart';

abstract class PurchaseListRepository {
  /// Active purchase list (items + unmapped orders) for an optional seller.
  Future<Either<Failure, PurchaseListResult>> getList(int? sellerId);

  /// Re-extract from ACCEPT orders (idempotent); returns the refreshed result.
  Future<Either<Failure, PurchaseListResult>> extract(int? sellerId);

  /// Completed purchases (remainingQty <= 0 && purchasedQty > 0), read-only.
  Future<Either<Failure, List<PurchaseListItem>>> getCompleted(int? sellerId);

  /// Record a purchase against a line. [quantity] may be negative for corrections.
  Future<Either<Failure, void>> recordPurchase(
    int itemId,
    String purchasedOn,
    int quantity,
  );

  /// Replace the manual quantity of a line with an absolute value (0+).
  Future<Either<Failure, void>> adjustManualQty(int itemId, int manualQty);

  /// Add (or accumulate) a manual line for a product. [quantity] >= 1.
  Future<Either<Failure, void>> addManual(int productId, int quantity);
}
