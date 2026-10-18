import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_record.dart';
import '../repositories/purchase_list_repository.dart';

/// Lazy recent purchases of a product (PLAN 2609_29 D9 · FEATURE_2610_09 D25).
///
/// ⚠️ [sellerId] null = every seller, newest first, mixed. The history box
/// filters one seller with its own dropdown (D25).
/// Not part of the list response — the intake card calls it when
/// [최근 구매이력] opens. The list and completed tabs **reuse this use case** (D21).
class GetRecentPurchasesUseCase {
  final PurchaseListRepository repository;

  GetRecentPurchasesUseCase({required this.repository});

  Future<Either<Failure, List<PurchaseRecord>>> call(
    int productId, {
    int limit = 5,
    int? sellerId,
  }) {
    return repository.recentPurchases(
      productId,
      limit: limit,
      sellerId: sellerId,
    );
  }
}
