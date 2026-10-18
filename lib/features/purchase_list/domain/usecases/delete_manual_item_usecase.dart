import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

/// Deletes a manual line — [제거] (FEATURE_2610_09 D77).
class DeleteManualItemUseCase {
  final PurchaseListRepository repository;

  DeleteManualItemUseCase({required this.repository});

  Future<Either<Failure, void>> call(int itemId) {
    return repository.deleteManual(itemId);
  }
}
