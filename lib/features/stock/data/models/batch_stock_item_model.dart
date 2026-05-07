import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_item_entity.dart';

class BatchStockItemModel extends BatchStockItemEntity {
  const BatchStockItemModel({
    required String barcodeId,
    required int quantity,
    required String name,
  }) : super(
    barcodeId: barcodeId,
    quantity: quantity,
    name: name,
  );

  factory BatchStockItemModel.fromJson(Map<String, dynamic> json) {
    return BatchStockItemModel(
      barcodeId: json['barcodeId'] as String,
      quantity: json['quantity'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'barcodeId': barcodeId,
    'quantity': quantity,
    'name': name,
  };
}
