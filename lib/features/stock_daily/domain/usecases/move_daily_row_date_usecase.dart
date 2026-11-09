import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/stock_daily_repository.dart';

/// The 「날짜 바꾸기」 sheet of the daily view (FEATURE_2611_21 D9) — one row
/// to a new day (an order outbound row moves with its order, D4).
class MoveDailyRowDateUseCase {
  final StockDailyRepository repository;

  MoveDailyRowDateUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(int movementId, String newMovedOn) =>
      repository.moveDate(movementId, newMovedOn);
}
