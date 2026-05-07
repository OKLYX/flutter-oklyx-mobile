import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock_log_entity.dart';

class StockLogModel extends StockLogEntity {
  const StockLogModel({
    required int stockId,
    required String barcodeId,
    required String productName,
    required int inStock,
    required int stockAdd,
    required int stockSub,
    required DateTime createdDate,
  }) : super(
    stockId: stockId,
    barcodeId: barcodeId,
    productName: productName,
    inStock: inStock,
    stockAdd: stockAdd,
    stockSub: stockSub,
    createdDate: createdDate,
  );

  factory StockLogModel.fromJson(Map<String, dynamic> json) {
    return StockLogModel(
      stockId: (json['stockId'] as dynamic) ?? 0,
      barcodeId: json['barcodeId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      inStock: (json['inStock'] as dynamic) ?? 0,
      stockAdd: (json['stockAdd'] as dynamic) ?? 0,
      stockSub: (json['stockSub'] as dynamic) ?? 0,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stockId': stockId,
    'barcodeId': barcodeId,
    'productName': productName,
    'inStock': inStock,
    'stockAdd': stockAdd,
    'stockSub': stockSub,
    'createdDate': createdDate.toIso8601String(),
  };
}
