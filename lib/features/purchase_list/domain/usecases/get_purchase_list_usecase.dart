import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_result.dart';
import '../repositories/purchase_list_repository.dart';

class GetPurchaseListUseCase {
  final PurchaseListRepository repository;

  GetPurchaseListUseCase({required this.repository});

  Future<Either<Failure, PurchaseListResult>> call(int? sellerId) {
    return repository.getList(sellerId);
  }
}
