import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

/// Moves a manual line to another seller (FEATURE_2610_09 D13 · D24 · D26).
class ChangeManualSellerUseCase {
  final PurchaseListRepository repository;

  ChangeManualSellerUseCase({required this.repository});

  Future<Either<Failure, void>> call(int itemId, int sellerId) {
    return repository.changeManualSeller(itemId, sellerId);
  }
}
