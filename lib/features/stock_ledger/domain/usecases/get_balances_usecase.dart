import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_balance.dart';
import '../repositories/stock_ledger_repository.dart';

/// (물품 × 판매자) 잔량 조회 (PLAN 2609_28 D14 / 2609_29 D5).
class GetBalancesUseCase {
  final StockLedgerRepository repository;

  GetBalancesUseCase({required this.repository});

  Future<Either<Failure, List<StockBalance>>> call({
    int? productId,
    int? sellerId,
    String? keyword,
  }) {
    return repository.balances(
      productId: productId,
      sellerId: sellerId,
      keyword: keyword,
    );
  }
}
