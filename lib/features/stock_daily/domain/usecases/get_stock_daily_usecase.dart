import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_daily.dart';
import '../repositories/stock_daily_repository.dart';

/// One day of the ledger (FEATURE_2610_19 D119 · D123 · D147).
class GetStockDailyUseCase {
  final StockDailyRepository repository;

  GetStockDailyUseCase({required this.repository});

  Future<Either<Failure, StockDaily>> call(String date) =>
      repository.getDaily(date);
}
