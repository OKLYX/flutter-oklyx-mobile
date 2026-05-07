import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'batch_stock_item_model.dart';

class BatchStockRequestModel extends BatchStockRequestEntity {
  const BatchStockRequestModel({
    required StockType type,
    required List<BatchStockItemModel> items,
  }) : super(
    type: type,
    items: items,
  );

  factory BatchStockRequestModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List)
        .map((item) => BatchStockItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return BatchStockRequestModel(
      type: json['type'] == 'IN' ? StockType.IN : StockType.OUT,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type == StockType.IN ? 'IN' : 'OUT',
    'items': (items as List<BatchStockItemModel>)
        .map((item) => item.toJson())
        .toList(),
  };
}
