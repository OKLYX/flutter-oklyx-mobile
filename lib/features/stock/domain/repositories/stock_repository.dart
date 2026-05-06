import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

abstract class StockRepository {
  Future<Either<Failure, GetStockResponse>> getCurrentStock(String barcodeId);
  Future<Either<Failure, CreateStockResponse>> createStock(
    CreateStockRequest data,
  );
}
