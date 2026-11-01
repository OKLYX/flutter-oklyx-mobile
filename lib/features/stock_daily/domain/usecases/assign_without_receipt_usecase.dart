import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import '../repositories/stock_daily_repository.dart';

/// 「영수증 없이 판매자 정하기」 of the screen day (FEATURE_2611_01 D2 · D4) —
/// the mode is `RECEIPT_LATER` or `NO_RECEIPT`.
class AssignWithoutReceiptUseCase {
  final StockDailyRepository repository;

  AssignWithoutReceiptUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String movedOn, String mode, int sellerId,
          List<ReceiptLineParams> lines) =>
      repository.assignWithoutReceipt(movedOn, mode, sellerId, lines);
}
