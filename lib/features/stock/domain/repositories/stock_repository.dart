import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

abstract class StockRepository {
  Future<Either<Failure, GetStockResponse>> getCurrentStock(String barcodeId);
  Future<Either<Failure, CreateStockResponse>> createStock(
    CreateStockRequest data,
  );
  Future<Either<Failure, BatchStockResponseEntity>> createBatchStock(
    BatchStockRequestEntity request,
  );
  Future<Either<Failure, GetStockLogsResponseEntity>> getStockLogs(
    GetStockLogsParamsEntity params,
  );
}
