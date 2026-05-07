import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';

class GetStockLogsUseCase {
  final StockRepository repository;

  GetStockLogsUseCase(this.repository);

  Future<Either<Failure, GetStockLogsResponseEntity>> call(GetStockLogsParamsEntity params) {
    return repository.getStockLogs(params);
  }
}
