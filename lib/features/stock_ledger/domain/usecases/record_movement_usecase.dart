import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_enums.dart';
import '../entities/stock_movement.dart';
import '../repositories/stock_ledger_repository.dart';

/// 입고·반품입고·폐기·조정 1건 기록 (PLAN 2609_28 D6~D10).
///
/// ⚠️ 사유·참조의 조합 규칙은 서버가 정본이다 — 화면은 400 원문을 그대로 보여준다.
class RecordMovementUseCase {
  final StockLedgerRepository repository;

  RecordMovementUseCase({required this.repository});

  Future<Either<Failure, StockMovement>> call({
    required int productId,
    int? sellerId,
    required StockMovementType movementType,
    required int quantity,
    StockReason? reason,
    String? reasonNote,
    double? unitPrice,
    int? orderClaimId,
    int? purchaseRecordId,
    required String movedOn,
  }) {
    return repository.record(
      productId: productId,
      sellerId: sellerId,
      movementType: movementType,
      quantity: quantity,
      reason: reason,
      reasonNote: reasonNote,
      unitPrice: unitPrice,
      orderClaimId: orderClaimId,
      purchaseRecordId: purchaseRecordId,
      movedOn: movedOn,
    );
  }
}
