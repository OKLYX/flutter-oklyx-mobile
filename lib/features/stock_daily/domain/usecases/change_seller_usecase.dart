import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/stock_daily_repository.dart';

/// 「판매자 바꾸기」 of the daily view (FEATURE_2611_01 D7 · D15).
class ChangeSellerUseCase {
  final StockDailyRepository repository;

  ChangeSellerUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(
          int sellerId, List<int> movementIds, List<int> shareRecordIds) =>
      repository.changeSeller(sellerId, movementIds, shareRecordIds);
}
