import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';

class GetStockUseCase {
  final StockRepository repository;

  GetStockUseCase(this.repository);

  Future<Either<Failure, GetStockResponse>> call(String barcodeId) {
    return repository.getCurrentStock(barcodeId);
  }
}
