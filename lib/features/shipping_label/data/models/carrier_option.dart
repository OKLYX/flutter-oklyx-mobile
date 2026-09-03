import 'package:equatable/equatable.dart';

/// 단건 발송처리 택배사 드롭다운 항목.
///
/// 서버로 되돌려 보내는 값은 [carrierId] 뿐 — 마켓 코드(deliveryCompanyCode)는 서버가
/// 해석한다(PLAN 2609_11 D2). [deliveryCompanyCode] 는 화면 표시 보조용이다.
class CarrierOption extends Equatable {
  final int carrierId;
  final String carrierName;
  final String deliveryCompanyCode;

  const CarrierOption({
    required this.carrierId,
    required this.carrierName,
    required this.deliveryCompanyCode,
  });

  factory CarrierOption.fromJson(Map<String, dynamic> json) => CarrierOption(
        carrierId: (json['carrierId'] as num).toInt(),
        carrierName: json['carrierName']?.toString() ?? '',
        deliveryCompanyCode: json['deliveryCompanyCode']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [carrierId, carrierName, deliveryCompanyCode];
}
