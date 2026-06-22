import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_list_item.dart';
import 'purchase_line_model.dart';

class PurchaseListItemModel extends PurchaseListItem {
  PurchaseListItemModel({
    required int productId,
    required String productName,
    required int neededQty,
    required int purchasedQty,
    required int remainingQty,
    required List<PurchaseLineModel> lines,
  }) : super(
          productId: productId,
          productName: productName,
          neededQty: neededQty,
          purchasedQty: purchasedQty,
          remainingQty: remainingQty,
          lines: lines,
        );

  factory PurchaseListItemModel.fromJson(Map<String, dynamic> json) {
    final linesJson = (json['lines'] as List<dynamic>?) ?? const [];
    return PurchaseListItemModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      neededQty: json['neededQty'] as int,
      purchasedQty: json['purchasedQty'] as int,
      remainingQty: json['remainingQty'] as int,
      lines: linesJson
          .map((e) => PurchaseLineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
