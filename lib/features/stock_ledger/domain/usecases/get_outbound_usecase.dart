import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/outbound_order.dart';
import '../repositories/stock_ledger_repository.dart';

/// 출고 대상 조회 (PLAN 2609_28 D11) — 주문에서 출발한다.
class GetOutboundUseCase {
  final StockLedgerRepository repository;

  GetOutboundUseCase({required this.repository});

  Future<Either<Failure, OutboundResult>> call({int? sellerId, String? status}) {
    return repository.outbound(sellerId: sellerId, status: status);
  }
}
