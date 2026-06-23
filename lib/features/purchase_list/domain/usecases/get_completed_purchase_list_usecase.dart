import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';
import '../repositories/purchase_list_repository.dart';

class GetCompletedPurchaseListUseCase {
  final PurchaseListRepository repository;

  GetCompletedPurchaseListUseCase({required this.repository});

  Future<Either<Failure, List<PurchaseListItem>>> call(
    int? sellerId,
    String? from,
    String? to,
  ) {
    return repository.getCompleted(sellerId, from, to);
  }
}
