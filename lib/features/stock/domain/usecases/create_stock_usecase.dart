import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';

class CreateStockUseCase {
  final StockRepository repository;

  CreateStockUseCase(this.repository);

  Future<Either<Failure, CreateStockResponse>> call(CreateStockRequest params) {
    return repository.createStock(params);
  }
}
