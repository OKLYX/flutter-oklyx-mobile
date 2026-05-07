import 'package:flutter_oklyn_mobile/features/stock/data/models/batch_stock_request_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/models/batch_stock_response_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/models/get_stock_logs_params_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/models/get_stock_logs_response_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

abstract class StockRemoteDatasource {
  Future<GetStockResponse> getCurrentStock(String barcodeId);
  Future<CreateStockResponse> createStock(CreateStockRequest data);
  Future<BatchStockResponseModel> createBatchStock(BatchStockRequestModel request);
  Future<GetStockLogsResponseModel> getStockLogs(GetStockLogsParamsModel params);
}
