import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_work.dart';
import '../repositories/stock_ledger_repository.dart';

/// 「출고 작업」 save (FEATURE_2611_34 D3 · D34) — every line of one tab in
/// one request. Thin delegate to [StockLedgerRepository].
class OutboundWorkUseCase {
  final StockLedgerRepository repository;

  OutboundWorkUseCase({required this.repository});

  /// Saves every line at once; [fallback] shows when the server is silent.
  Future<Either<Failure, void>> save({
    required String movedOn,
    required List<OutboundWorkLineRequest> lines,
    required String fallback,
  }) =>
      repository.outboundWork(
        movedOn: movedOn,
        lines: lines,
        fallback: fallback,
      );
}
