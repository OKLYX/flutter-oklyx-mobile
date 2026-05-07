import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';

class CreateBatchStockUseCase {
  final StockRepository repository;

  CreateBatchStockUseCase(this.repository);

  Future<Either<Failure, BatchStockResponseEntity>> call(BatchStockRequestEntity request) {
    return repository.createBatchStock(request);
  }
}
