import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_result.dart';
import '../repositories/purchase_list_repository.dart';

class ExtractPurchaseListUseCase {
  final PurchaseListRepository repository;

  ExtractPurchaseListUseCase({required this.repository});

  Future<Either<Failure, PurchaseListResult>> call(int? sellerId) {
    return repository.extract(sellerId);
  }
}
