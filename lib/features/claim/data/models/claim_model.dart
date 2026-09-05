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
    super.collectStatus,
    super.reshipInvoiceNo,
    super.reshipCarrierCode,
    super.requesterName,
    required super.receivedAt,
    super.sellerId,
    super.sellerName,
    super.orderItemId,
    required super.linked,
    super.availableActions,
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
      // 교환 전용 · 원문 그대로(05). 구버전 서버 응답에는 필드가 없다 → null.
      collectStatus: json['collectStatus'] as String?,
      reshipInvoiceNo: json['reshipInvoiceNo'] as String?,
      reshipCarrierCode: json['reshipCarrierCode'] as String?,
      requesterName: json['requesterName'] as String?,
      // 서버는 ISO LocalDateTime 문자열을 준다. 파싱 실패해도 화면이 죽지 않게 epoch 로 떨어뜨린다.
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sellerId: (json['sellerId'] as num?)?.toInt(),
      sellerName: json['sellerName'] as String?,
      orderItemId: (json['orderItemId'] as num?)?.toInt(),
      linked: json['linked'] as bool? ?? false,
      // 구버전 서버(필드 없음)·비-ADMIN(빈 목록) 모두 빈 리스트로 떨어진다 — 크래시 없음.
      availableActions: _parseActions(json['availableActions']),
    );
  }

  /// 실행 가능 액션 파싱(FEATURE_2609_21 D1).
  ///
  /// 🔴 `action`·`requires` 는 **문자열 그대로** 둔다 — enum 으로 좁히면 서버가 값을 늘리는 날
  /// (교환 4종) 구버전 앱이 파싱에서 죽는다. 모르는 값의 처리는 화면이 정한다(버튼을 안 그린다).
  static List<ClaimAction> _parseActions(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => ClaimAction(
            action: e['action'] as String? ?? '',
            label: e['label'] as String? ?? '',
            requires: e['requires'] as String? ?? '',
            choices: _parseChoices(e['choices']),
            irreversible: e['irreversible'] == true,
          ),
        )
        // 코드가 비면 서버에 되돌려 보낼 식별자가 없다 — 그릴 수 없는 버튼이다.
        .where((a) => a.action.isNotEmpty)
        .toList();
  }

  /// 선택지는 반품 3액션에서 항상 빈 배열이지만 지금 파싱한다 —
  /// 07(교환 거부 사유)에서 모델을 다시 열면 그 사이 웹·앱 모델이 갈린다.
  static List<ActionChoice> _parseChoices(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => ActionChoice(
            code: e['code'] as String? ?? '',
            label: e['label'] as String? ?? '',
          ),
        )
        .where((c) => c.code.isNotEmpty)
        .toList();
  }

  /// 모르는 종류는 기본 탭인 반품으로 둔다 — 목록이 통째로 비는 것보다 낫다.
  static ClaimType _parseType(String? v) {
    for (final t in ClaimType.values) {
      if (t.wire == v) return t;
    }
    return ClaimType.returnClaim;
  }
}

/// `POST /api/admin/claims/{id}/actions` 응답 → [ClaimActionResult].
///
/// ⚠️ 502(쿠팡 거절) 응답도 **같은 모양**으로 `data` 에 실려 온다 — 성공/실패에서 서로 다른
/// 스키마를 파싱하지 않는다. 실패 경로의 파싱은 Repository 가 한다(상태 코드가 필요하므로).
class ClaimActionResultModel extends ClaimActionResult {
  const ClaimActionResultModel({
    required super.claimId,
    required super.action,
    required super.succeeded,
    super.resultCode,
    super.resultMessage,
  });

  factory ClaimActionResultModel.fromJson(Map<String, dynamic> json) {
    return ClaimActionResultModel(
      claimId: (json['claimId'] as num?)?.toInt() ?? 0,
      action: json['action'] as String? ?? '',
      succeeded: json['succeeded'] == true,
      resultCode: json['resultCode'] as String?,
      resultMessage: json['resultMessage'] as String?,
    );
  }
}
