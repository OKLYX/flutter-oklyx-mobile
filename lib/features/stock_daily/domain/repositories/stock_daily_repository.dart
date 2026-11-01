import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import '../entities/stock_daily.dart';

/// 「그날 입출고 내역」 data (FEATURE_2610_19 D119 · D121).
abstract class StockDailyRepository {
  Future<Either<Failure, StockDaily>> getDaily(String date);

  Future<Either<Failure, Unit>> assign(
    String movedOn,
    File photo,
    CreateReceiptParams params,
  );
}
