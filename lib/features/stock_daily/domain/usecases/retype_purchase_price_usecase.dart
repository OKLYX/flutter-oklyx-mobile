import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_daily.dart';
import '../repositories/stock_daily_repository.dart';

/// 「매입가 넣기」 of the daily view (FEATURE_2611_16 D2 · D7 · D12) — the
/// amounts of the checked rows and shares, with an optional receipt photo.
class RetypePurchasePriceUseCase {
  final StockDailyRepository repository;

  RetypePurchasePriceUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String movedOn, File? photo, int? cardId,
          List<PurchasePriceLine> lines) =>
      repository.retypePrices(movedOn, photo, cardId, lines);
}
