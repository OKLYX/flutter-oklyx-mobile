import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/purchase_list_repository.dart';

class RecordPurchaseUseCase {
  final PurchaseListRepository repository;

  RecordPurchaseUseCase({required this.repository});

  Future<Either<Failure, void>> call(
    int itemId,
    String purchasedOn,
    int quantity, {
    double? totalAmount,
    double? unitPrice,
    bool reflectToBasePrice = true,
  }) {
    return repository.recordPurchase(
      itemId,
      purchasedOn,
      quantity,
      totalAmount: totalAmount,
      unitPrice: unitPrice,
      reflectToBasePrice: reflectToBasePrice,
    );
  }
}
