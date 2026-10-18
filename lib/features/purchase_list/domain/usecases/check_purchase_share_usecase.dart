import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

/// [매입 완료] · [오늘 매입 안 함] on one (product × seller) share and the undo
/// (FEATURE_2610_09 D57 · D61 · D62).
class CheckPurchaseShareUseCase {
  final PurchaseListRepository repository;

  CheckPurchaseShareUseCase({required this.repository});

  /// [status] = `PURCHASED` · `NOT_NEEDED` · `TOMORROW`.
  Future<Either<Failure, void>> call(
      int productId, int sellerId, String status) {
    return repository.check(productId, sellerId, status);
  }

  Future<Either<Failure, void>> cancel(int checkId) {
    return repository.cancelCheck(checkId);
  }
}
