import 'package:flutter/foundation.dart' show debugPrint;

/// 클레임(반품·교환) 도메인 (FEATURE_2609_18 Stage A).
///
/// **용도**: `GET /api/claims` 응답의 도메인 표현. 반품/교환 목록·상세 화면이 공유한다.
/// **파일**: lib/features/claim/domain/entities/claim.dart
///
/// 🔴 **와이어 값은 백엔드 enum 그대로 SCREAMING_SNAKE 다**(PLAN §3.1).
/// Dart 이름(camelCase)과 다르므로 `ClaimStatus.values.byName` 은
/// `IN_PROGRESS`·`PENDING_REVIEW`
/// 에서 반드시 실패한다. 직렬화·역직렬화는 **오직 `wire` 값**을 근거로 한다.

/// 클레임 종류. 목록 화면의 탭 축이다(반품 ↔ 교환) — 서버 조회 파라미터로 그대로 나간다.
enum ClaimType {
  returnClaim('RETURN'),
  exchange('EXCHANGE');

  const ClaimType(this.wire);

  /// 서버로 보내고 서버에서 받는 값. `name`(camelCase)이 아니다.
  final String wire;
}

/// 플랫폼 중립 클레임 상태. 원문 상태 코드는 [Claim.platformStatus] 에 그대로 남는다.
enum ClaimStatus {
  received('RECEIVED'),
  inProgress('IN_PROGRESS'),
  done('DONE'),
  rejected('REJECTED'),
  withdrawn('WITHDRAWN'),
  pendingReview('PENDING_REVIEW'),
  stale('STALE');

  const ClaimStatus(this.wire);

  /// 서버로 보내고 서버에서 받는 값. `name`(camelCase)이 아니다.
  final String wire;
}

/// 와이어 문자열 → [ClaimStatus].
///
/// 모르는 값(신규 코드·null) → [ClaimStatus.received](가장 안전한 미완결) + [debugPrint].
/// 백엔드가 상태를 추가해도 앱이 죽지 않는다.
///
/// ❌ `ClaimStatus.values.byName(...)` / `firstWhere((e) => e.name == v)` 금지 —
/// enum 이름은 camelCase 라 `IN_PROGRESS` 를 절대 찾지 못한다.
ClaimStatus parseClaimStatus(String? v) {
  for (final s in ClaimStatus.values) {
    if (s.wire == v) return s;
  }
  debugPrint('[claim] unknown status: $v');
  return ClaimStatus.received;
}

/// 귀책 코드 → 한글 라벨.
///
/// **빈 맵으로 시작한다** — 쿠팡 `faultByType` 의 실제 값 집합이 아직 확인되지 않았고,
/// 추측한 매핑은 틀린 라벨을 보여준다. 02(웹)의 `FAULT_TYPE_LABEL` 과 같은 정책이다
/// (웹/앱의 귀책 표기가 갈리면 안 된다). 실값이 확인되면 여기와 웹을 **함께** 채운다.
const faultTypeLabel = <String, String>{};

/// 귀책 표시용 텍스트. 미지정 값은 원문 그대로, null 은 '-'.
///
/// ⚠️ 화면은 [faultTypeLabel] 을 직접 읽지 말고 반드시 이 함수를 쓴다 —
/// 맵을 직접 읽으면 미지정 값이 null 이 되어 빈칸으로 보인다.
String faultTypeText(String? v) => v == null ? '-' : (faultTypeLabel[v] ?? v);

/// 상태 → 한글 라벨. 목록 카드·상세·필터 칩이 공유하는 유일한 라벨표다.
const claimStatusLabel = <ClaimStatus, String>{
  ClaimStatus.received: '접수',
  ClaimStatus.inProgress: '진행중',
  ClaimStatus.done: '완료',
  ClaimStatus.rejected: '거부',
  ClaimStatus.withdrawn: '철회',
  ClaimStatus.pendingReview: '확인요청',
  ClaimStatus.stale: '확인필요',
};

String getClaimStatusLabel(ClaimStatus status) =>
    claimStatusLabel[status] ?? status.wire;

/// 종류 → 한글 라벨. 탭 라벨·빈 상태 문구·상세 제목이 공유하는 단 하나의 명칭표다.
///
/// ⚠️ 화면에서 '반품'/'교환' 문자열을 직접 쓰지 말 것 — 세 곳에 흩어지면 탭마다 단어가 갈린다.
const claimTypeLabel = <ClaimType, String>{
  ClaimType.returnClaim: '반품',
  ClaimType.exchange: '교환',
};

String getClaimTypeLabel(ClaimType type) => claimTypeLabel[type] ?? type.wire;

/// 반품에서 실제로 나타나는 상태만 칩으로 낸다(PLAN §3.1).
/// `IN_PROGRESS`·`REJECTED`·`WITHDRAWN` 은 교환 전용이라 반품 목록에는 등장하지 않는다.
const returnStatusFilters = <ClaimStatus>[
  ClaimStatus.received,
  ClaimStatus.done,
  ClaimStatus.pendingReview,
];

/// 교환에서 실제로 나타나는 상태만 칩으로 낸다(PLAN §3.1).
/// `pendingReview` 는 반품 전용이라 여기 없다 — 두 목록이 다른 것이 의도다.
///
/// ⚠️ `stale` 칩은 [returnStatusFilters] 와 **함께** 채운다(05 부록의 몫) — 지금은 양쪽 모두 없다.
const exchangeStatusFilters = <ClaimStatus>[
  ClaimStatus.received,
  ClaimStatus.inProgress,
  ClaimStatus.done,
  ClaimStatus.rejected,
  ClaimStatus.withdrawn,
];

/// 클레임 1건. 목록·상세가 같은 객체를 쓴다(상세 API 재조회 없음 — 주문 상세와 동일).
class Claim {
  final int id;

  /// 'COUPANG' 등 — 처리 액션이 붙기 전인 지금부터 응답에 들어 있다(D5).
  final String platform;
  final ClaimType claimType;

  /// 정규화 상태. 필터·라벨은 전부 이 값으로만 동작한다.
  final ClaimStatus status;

  /// 플랫폼 원문 상태('UC' 등). 정보 손실 방지용 — **상세에만** 노출한다.
  final String platformStatus;
  final String externalClaimId;
  final String externalOrderId;
  final String? itemName;
  final int quantity;
  final String? reasonCode;
  final String? reasonText;
  final String? faultType;
  /// ⚠️ 교환에서는 **항상 null** 이다(06) — 교환 배송비를 이 필드로 읽지 말 것.
  final int? returnShippingCharge;
  final String? collectInvoiceNo;
  final String? collectCarrierCode;

  /// 교환 재발송 송장. 반품에서는 항상 null 이다(교환 전용 — 06).
  final String? reshipInvoiceNo;
  final String? reshipCarrierCode;
  final String? requesterName;
  final DateTime receivedAt;
  final int? sellerId;
  final String? sellerName;
  final int? orderItemId;

  /// false = 주문 라인 미연결(D12). 매칭에 실패해도 클레임 자체는 저장된다.
  final bool linked;

  const Claim({
    required this.id,
    required this.platform,
    required this.claimType,
    required this.status,
    required this.platformStatus,
    required this.externalClaimId,
    required this.externalOrderId,
    this.itemName,
    required this.quantity,
    this.reasonCode,
    this.reasonText,
    this.faultType,
    this.returnShippingCharge,
    this.collectInvoiceNo,
    this.collectCarrierCode,
    this.reshipInvoiceNo,
    this.reshipCarrierCode,
    this.requesterName,
    required this.receivedAt,
    this.sellerId,
    this.sellerName,
    this.orderItemId,
    required this.linked,
  });
}
