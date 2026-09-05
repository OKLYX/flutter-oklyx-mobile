import '../../domain/entities/claim.dart';

/// `GET /api/claims` 응답 1건 → [Claim].
///
/// 관례는 `OrderModel` 과 같다 — 모델이 엔티티를 상속하고 `fromJson` 만 갖는다.
///
/// 🔴 `status`·`claimType` 은 **와이어 값(SCREAMING_SNAKE)** 이다.
/// `ClaimStatus.values.byName(...)` 은 `IN_PROGRESS`·`PENDING_REVIEW` 에서
/// 반드시 실패하므로 [parseClaimStatus] / `wire` 비교를 거친다.
class ClaimModel extends Claim {
  const ClaimModel({
    required super.id,
    required super.platform,
    required super.claimType,
    required super.status,
    required super.platformStatus,
    required super.externalClaimId,
    required super.externalOrderId,
    super.itemName,
    required super.quantity,
    super.reasonCode,
    super.reasonText,
    super.faultType,
    super.returnShippingCharge,
    super.collectInvoiceNo,
    super.collectCarrierCode,
    super.requesterName,
    required super.receivedAt,
    super.sellerId,
    super.sellerName,
    super.orderItemId,
    required super.linked,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: (json['id'] as num).toInt(),
      platform: json['platform'] as String? ?? '',
      claimType: _parseType(json['claimType'] as String?),
      status: parseClaimStatus(json['status'] as String?),
      platformStatus: json['platformStatus'] as String? ?? '',
      externalClaimId: json['externalClaimId'] as String? ?? '',
      externalOrderId: json['externalOrderId'] as String? ?? '',
      itemName: json['itemName'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reasonCode: json['reasonCode'] as String?,
      reasonText: json['reasonText'] as String?,
      faultType: json['faultType'] as String?,
      returnShippingCharge: (json['returnShippingCharge'] as num?)?.toInt(),
      collectInvoiceNo: json['collectInvoiceNo'] as String?,
      collectCarrierCode: json['collectCarrierCode'] as String?,
      requesterName: json['requesterName'] as String?,
      // 서버는 ISO LocalDateTime 문자열을 준다. 파싱 실패해도 화면이 죽지 않게 epoch 로 떨어뜨린다.
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sellerId: (json['sellerId'] as num?)?.toInt(),
      sellerName: json['sellerName'] as String?,
      orderItemId: (json['orderItemId'] as num?)?.toInt(),
      linked: json['linked'] as bool? ?? false,
    );
  }

  /// 모르는 종류는 Stage A 범위인 반품으로 둔다 — 목록이 통째로 비는 것보다 낫다.
  static ClaimType _parseType(String? v) {
    for (final t in ClaimType.values) {
      if (t.wire == v) return t;
    }
    return ClaimType.returnClaim;
  }
}
