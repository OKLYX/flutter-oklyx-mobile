import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

/// Reads the stock link setting (FEATURE_2610_09 D65 · D71 · D72).
class GetStockLinkedUseCase {
  final PurchaseListRepository repository;

  GetStockLinkedUseCase({required this.repository});

  Future<Either<Failure, bool>> call() {
    return repository.getStockLinked();
  }
}
