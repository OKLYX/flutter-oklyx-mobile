import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_movement.dart';
import '../repositories/stock_ledger_repository.dart';

/// 원장 이력 조회. 기간 생략 시 서버가 최근 30일을 준다.
class GetMovementsUseCase {
  final StockLedgerRepository repository;

  GetMovementsUseCase({required this.repository});

  Future<Either<Failure, List<StockMovement>>> call({
    int? productId,
    int? sellerId,
    String? from,
    String? to,
  }) {
    return repository.movements(
      productId: productId,
      sellerId: sellerId,
      from: from,
      to: to,
    );
  }
}
