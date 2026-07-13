import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';

class CarrierModel extends Carrier {
  CarrierModel({
    required int id,
    required String name,
    required bool isActive,
  }) : super(
          id: id,
          name: name,
          isActive: isActive,
        );

  factory CarrierModel.fromJson(Map<String, dynamic> json) {
    return CarrierModel(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}
