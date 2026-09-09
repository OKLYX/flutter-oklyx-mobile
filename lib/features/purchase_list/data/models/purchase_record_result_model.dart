import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_record_result.dart';

class PurchaseRecordResultModel extends PurchaseRecordResult {
  PurchaseRecordResultModel({
    required int purchaseRecordId,
    required bool stockRecorded,
  }) : super(
          purchaseRecordId: purchaseRecordId,
          stockRecorded: stockRecorded,
        );

  factory PurchaseRecordResultModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRecordResultModel(
      purchaseRecordId: json['purchaseRecordId'] as int,
      stockRecorded: json['stockRecorded'] as bool? ?? false,
    );
  }
}
