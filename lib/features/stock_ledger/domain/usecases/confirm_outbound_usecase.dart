import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_movement.dart';
import '../repositories/stock_ledger_repository.dart';

/// 출고 확인 1건 (PLAN 2609_28 D12).
///
/// ❌ 여러 줄을 모아 한 번에 보내지 않는다 — 작업이 끊겼을 때 어디까지 처리했는지 복구되지 않는다.
class ConfirmOutboundUseCase {
  final StockLedgerRepository repository;

  ConfirmOutboundUseCase({required this.repository});

  Future<Either<Failure, List<StockMovement>>> call({
    required int orderLineId,
    required int productId,
    required int quantity,
    required String movedOn,
  }) {
    return repository.confirmOutbound(
      orderLineId: orderLineId,
      productId: productId,
      quantity: quantity,
      movedOn: movedOn,
    );
  }
}
