import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_work.dart';
import '../repositories/stock_ledger_repository.dart';

/// 「반품 재입고」 · 「교환 발송」 lookups and saves (FEATURE_2611_34 D16 ~
/// D33 · D38 · D42). Thin delegate to [StockLedgerRepository].
class ClaimWorkUseCase {
  final StockLedgerRepository repository;

  ClaimWorkUseCase({required this.repository});

  Future<Either<Failure, List<ClaimWork>>> claimsByReturnInvoice(
    String value,
  ) =>
      repository.claimsByReturnInvoice(value);

  Future<Either<Failure, List<ClaimWork>>> claimsByParcelInvoice(
    String value,
  ) =>
      repository.claimsByParcelInvoice(value);

  Future<Either<Failure, List<ShippedOrder>>> shippedOrders() =>
      repository.shippedOrders();

  Future<Either<Failure, List<ClaimWork>>> claimsByOrder(int orderId) =>
      repository.claimsByOrder(orderId);

  Future<Either<Failure, void>> returnWork({
    required String movedOn,
    required List<ClaimWorkLineRequest> lines,
    required String fallback,
  }) =>
      repository.returnWork(
        movedOn: movedOn,
        lines: lines,
        fallback: fallback,
      );

  Future<Either<Failure, List<ClaimWork>>> claimsByReshipInvoice(
    String value,
  ) =>
      repository.claimsByReshipInvoice(value);

  Future<Either<Failure, List<ClaimWork>>> openExchanges() =>
      repository.openExchanges();

  Future<Either<Failure, void>> exchangeWork({
    required String movedOn,
    required List<ClaimWorkLineRequest> lines,
    required String fallback,
  }) =>
      repository.exchangeWork(
        movedOn: movedOn,
        lines: lines,
        fallback: fallback,
      );
}
