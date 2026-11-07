import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_daily.dart';
import '../repositories/stock_daily_repository.dart';

/// The row sheet's one save of the daily view (FEATURE_2611_17 D5) — the
/// seller, price and receipt of one row or share, with an optional photo.
class EditDailyRowUseCase {
  final StockDailyRepository repository;

  EditDailyRowUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(
          String movedOn, File? photo, DailyRowEdit edit) =>
      repository.editRow(movedOn, photo, edit);
}
