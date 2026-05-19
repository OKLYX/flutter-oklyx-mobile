import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';

class CarrierRateModel extends CarrierRate {
  CarrierRateModel({
    required int id,
    required String carrier,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
  }) : super(
    id: id,
    carrier: carrier,
    type: type,
    cost: cost,
    effectiveDate: effectiveDate,
    isDefault: isDefault,
  );

  factory CarrierRateModel.fromJson(Map<String, dynamic> json) {
    return CarrierRateModel(
      id: json['id'] as int,
      carrier: json['carrier'] as String,
      type: json['type'] as String,
      cost: (json['cost'] as num).toDouble(),
      effectiveDate: json['effectiveDate'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carrier': carrier,
      'type': type,
      'cost': cost,
      'effectiveDate': effectiveDate,
      'isDefault': isDefault,
    };
  }
}
