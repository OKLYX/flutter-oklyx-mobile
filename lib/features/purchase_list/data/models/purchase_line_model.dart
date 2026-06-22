import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_line.dart';
import 'purchase_record_model.dart';

class PurchaseLineModel extends PurchaseLine {
  PurchaseLineModel({
    required int itemId,
    required int? orderItemId,
    required String source,
    required String? externalOrderId,
    required int autoQty,
    required int manualQty,
    required int purchasedQty,
    required List<PurchaseRecordModel> records,
  }) : super(
          itemId: itemId,
          orderItemId: orderItemId,
          source: source,
          externalOrderId: externalOrderId,
          autoQty: autoQty,
          manualQty: manualQty,
          purchasedQty: purchasedQty,
          records: records,
        );

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json) {
    final recordsJson = (json['records'] as List<dynamic>?) ?? const [];
    return PurchaseLineModel(
      itemId: json['itemId'] as int,
      orderItemId: json['orderItemId'] as int?,
      source: json['source'] as String,
      externalOrderId: json['externalOrderId'] as String?,
      autoQty: json['autoQty'] as int,
      manualQty: json['manualQty'] as int,
      purchasedQty: json['purchasedQty'] as int,
      records: recordsJson
          .map((e) => PurchaseRecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
