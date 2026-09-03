import 'package:equatable/equatable.dart';

/// 단건 발송처리 택배사 드롭다운 항목.
///
/// 식별자는 **마켓 코드 자체**다 — 쿠팡은 택배사 목록 API 가 없고 문서의 정적 코드표가
/// SSOT 라, 로컬 택배사 행이 없는 택배사가 대부분이다(PLAN 2609_11 D2 개정 2026-09-03).
/// 서버가 받은 코드를 화이트리스트로 검증하므로 임의 문자열은 쿠팡까지 가지 않는다.
///
/// [registered] = 택배사 관리에 등록해 둔 코드 — 목록 맨 위에 온다.
class CarrierOption extends Equatable {
  final String deliveryCompanyCode;
  final String carrierName;
  final bool registered;

  const CarrierOption({
    required this.deliveryCompanyCode,
    required this.carrierName,
    required this.registered,
  });

  factory CarrierOption.fromJson(Map<String, dynamic> json) => CarrierOption(
        deliveryCompanyCode: json['deliveryCompanyCode']?.toString() ?? '',
        carrierName: json['carrierName']?.toString() ?? '',
        registered: json['registered'] == true,
      );

  @override
  List<Object?> get props => [deliveryCompanyCode, carrierName, registered];
}
