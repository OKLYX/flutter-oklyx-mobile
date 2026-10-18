import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/receipt_detail.dart';
import '../repositories/purchase_list_repository.dart';

/// One receipt with its photo and lines — the [영수증] button of a recent
/// purchase row (FEATURE_2610_18 D93 ①).
class GetReceiptUseCase {
  final PurchaseListRepository repository;

  GetReceiptUseCase({required this.repository});

  Future<Either<Failure, ReceiptDetail>> call(int receiptId) {
    return repository.getReceipt(receiptId);
  }
}
