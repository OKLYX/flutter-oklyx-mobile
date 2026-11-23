import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_intake.dart';
import '../repositories/stock_ledger_repository.dart';

/// 「입고 작업」 calls (FEATURE_2611_33 D4 · D5) — barcode lookup and the
/// one-shot save. Thin delegate to [StockLedgerRepository].
class StockIntakeUseCase {
  final StockLedgerRepository repository;

  StockIntakeUseCase({required this.repository});

  /// Finds the product holding [value] as its barcode.
  Future<Either<Failure, IntakeBarcodeResult>> lookupBarcode(String value) =>
      repository.intakeBarcode(value);

  /// Saves every line at once; returns the new lot ids in line order.
  Future<Either<Failure, List<int>>> save({
    required String movedOn,
    required List<StockIntakeLine> lines,
  }) =>
      repository.intake(movedOn: movedOn, lines: lines);
}
