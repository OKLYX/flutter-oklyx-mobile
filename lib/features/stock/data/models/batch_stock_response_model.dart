import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

class BatchStockResponseModel extends BatchStockResponseEntity {
  const BatchStockResponseModel({
    required List<CreateStockResponse> items,
  }) : super(
    items: items,
  );

  factory BatchStockResponseModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List)
        .map((item) => CreateStockResponse.fromJson(item as Map<String, dynamic>))
        .toList();

    return BatchStockResponseModel(
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
  };
}
