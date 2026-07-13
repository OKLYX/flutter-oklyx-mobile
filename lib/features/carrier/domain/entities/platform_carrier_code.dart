/// 택배사의 플랫폼별 코드 엔티티.
///
/// 예: 택배사 CJ대한통운 → COUPANG 플랫폼에서의 배송사 코드(deliveryCompanyCode) = CJGLS.
class PlatformCarrierCode {
  final int id;
  final int carrierId;
  final String platform;
  final String deliveryCompanyCode;

  PlatformCarrierCode({
    required this.id,
    required this.carrierId,
    required this.platform,
    required this.deliveryCompanyCode,
  });

  PlatformCarrierCode copyWith({
    int? id,
    int? carrierId,
    String? platform,
    String? deliveryCompanyCode,
  }) {
    return PlatformCarrierCode(
      id: id ?? this.id,
      carrierId: carrierId ?? this.carrierId,
      platform: platform ?? this.platform,
      deliveryCompanyCode: deliveryCompanyCode ?? this.deliveryCompanyCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformCarrierCode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
