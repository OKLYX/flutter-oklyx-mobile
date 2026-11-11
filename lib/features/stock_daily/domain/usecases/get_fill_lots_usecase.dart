import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_fill.dart';
import '../repositories/stock_daily_repository.dart';

/// The lots [입고로 채우기] offers for one order outbound row without a lot
/// (FEATURE_2611_22 D15).
class GetFillLotsUseCase {
  final StockDailyRepository repository;

  GetFillLotsUseCase({required this.repository});

  Future<Either<Failure, List<FillLot>>> call(int movementId) =>
      repository.fillLots(movementId);
}
