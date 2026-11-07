import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_daily.dart';
import '../repositories/stock_daily_repository.dart';

/// That day's receipts for the row sheet's receipt choices (FEATURE_2611_17
/// D23).
class GetDayReceiptsUseCase {
  final StockDailyRepository repository;

  GetDayReceiptsUseCase({required this.repository});

  Future<Either<Failure, List<DayReceipt>>> call(String date) =>
      repository.getDayReceipts(date);
}
