import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

class AddManualItemUseCase {
  final PurchaseListRepository repository;

  AddManualItemUseCase({required this.repository});

  Future<Either<Failure, void>> call(int productId, int quantity) {
    return repository.addManual(productId, quantity);
  }
}
