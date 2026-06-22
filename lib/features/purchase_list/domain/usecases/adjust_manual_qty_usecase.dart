import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

class AdjustManualQtyUseCase {
  final PurchaseListRepository repository;

  AdjustManualQtyUseCase({required this.repository});

  Future<Either<Failure, void>> call(int itemId, int manualQty) {
    return repository.adjustManualQty(itemId, manualQty);
  }
}
