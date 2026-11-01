import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import '../repositories/stock_daily_repository.dart';

/// Receipt assignment of the screen day (FEATURE_2610_19 D118 · D121).
class AssignReceiptUseCase {
  final StockDailyRepository repository;

  AssignReceiptUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(
          String movedOn, File photo, CreateReceiptParams params) =>
      repository.assign(movedOn, photo, params);
}
