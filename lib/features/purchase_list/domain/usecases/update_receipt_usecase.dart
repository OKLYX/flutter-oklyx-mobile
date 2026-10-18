import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/update_receipt_params.dart';
import '../entities/receipt_detail.dart';
import '../repositories/purchase_list_repository.dart';

/// Receipt header edit — [수정] of the receipt sheet (FEATURE_2610_18 D100 ·
/// D102). Right = the receipt as saved.
class UpdateReceiptUseCase {
  final PurchaseListRepository repository;

  UpdateReceiptUseCase({required this.repository});

  Future<Either<Failure, ReceiptDetail>> call(
    int receiptId,
    UpdateReceiptParams params,
  ) {
    return repository.updateReceipt(receiptId, params);
  }
}
