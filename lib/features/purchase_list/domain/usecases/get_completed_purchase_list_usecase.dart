import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';
import '../repositories/purchase_list_repository.dart';

class GetCompletedPurchaseListUseCase {
  final PurchaseListRepository repository;

  GetCompletedPurchaseListUseCase({required this.repository});

  /// Processing-day range + optional seller (FEATURE_2610_09 D5 · D63).
  Future<Either<Failure, List<PurchaseListItem>>> call(
    String? from,
    String? to, {
    int? sellerId,
  }) {
    return repository.getCompleted(from, to, sellerId);
  }
}
