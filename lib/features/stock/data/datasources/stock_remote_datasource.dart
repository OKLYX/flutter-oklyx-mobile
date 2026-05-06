import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

abstract class StockRemoteDatasource {
  Future<GetStockResponse> getCurrentStock(String barcodeId);
  Future<CreateStockResponse> createStock(CreateStockRequest data);
}
