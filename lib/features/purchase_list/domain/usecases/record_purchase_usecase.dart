import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_record_result.dart';
import '../repositories/purchase_list_repository.dart';

class RecordPurchaseUseCase {
  final PurchaseListRepository repository;

  RecordPurchaseUseCase({required this.repository});

  /// 입고 1회 — 물품 × 판매자(PLAN 2609_29 D1·D3).
  Future<Either<Failure, PurchaseRecordResult>> call(
    int productId,
    int sellerId,
    String purchasedOn,
    int quantity, {
    double? totalAmount,
    double? unitPrice,
    bool reflectToBasePrice = true,
    bool recordStock = true,
  }) {
    return repository.recordPurchase(
      productId,
      sellerId,
      purchasedOn,
      quantity,
      totalAmount: totalAmount,
      unitPrice: unitPrice,
      reflectToBasePrice: reflectToBasePrice,
      recordStock: recordStock,
    );
  }
}
