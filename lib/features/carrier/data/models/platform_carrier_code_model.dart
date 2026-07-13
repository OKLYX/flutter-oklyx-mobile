import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/platform_carrier_code.dart';

class PlatformCarrierCodeModel extends PlatformCarrierCode {
  PlatformCarrierCodeModel({
    required int id,
    required int carrierId,
    required String platform,
    required String deliveryCompanyCode,
  }) : super(
          id: id,
          carrierId: carrierId,
          platform: platform,
          deliveryCompanyCode: deliveryCompanyCode,
        );

  factory PlatformCarrierCodeModel.fromJson(Map<String, dynamic> json) {
    return PlatformCarrierCodeModel(
      id: json['id'] as int,
      carrierId: json['carrierId'] as int,
      platform: json['platform'] as String,
      deliveryCompanyCode: json['deliveryCompanyCode'] as String,
    );
  }
}
