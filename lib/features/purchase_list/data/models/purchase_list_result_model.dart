import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_list_result.dart';
import 'purchase_list_item_model.dart';
import 'unmapped_order_model.dart';

class PurchaseListResultModel extends PurchaseListResult {
  PurchaseListResultModel({
    required List<PurchaseListItemModel> items,
    required List<PurchaseListItemModel> skippedToday,
    required List<UnmappedOrderModel> unmappedOrders,
  }) : super(
          items: items,
          skippedToday: skippedToday,
          unmappedOrders: unmappedOrders,
        );

  factory PurchaseListResultModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>?) ?? const [];
    final skippedJson = (json['skippedToday'] as List<dynamic>?) ?? const [];
    final unmappedJson = (json['unmappedOrders'] as List<dynamic>?) ?? const [];
    return PurchaseListResultModel(
      items: itemsJson
          .map((e) => PurchaseListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      skippedToday: skippedJson
          .map((e) => PurchaseListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unmappedOrders: unmappedJson
          .map((e) => UnmappedOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
