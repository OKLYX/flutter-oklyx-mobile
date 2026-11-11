import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_fill.dart';
import '../repositories/stock_daily_repository.dart';

/// [채우기] of both sheets (FEATURE_2611_22 D3): per lot, the order outbound
/// rows without a lot it fills.
class FillOutboundUseCase {
  final StockDailyRepository repository;

  FillOutboundUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(List<FillRequestLot> fills) =>
      repository.fill(fills);
}
