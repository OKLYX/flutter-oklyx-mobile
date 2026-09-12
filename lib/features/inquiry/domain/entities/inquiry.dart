import 'package:flutter/foundation.dart' show debugPrint;

/// 고객문의 도메인 (FEATURE_2609_36 / 2609_23 백엔드).
///
/// **용도**: `GET /api/inquiries` 응답 1건의 도메인 표현. 목록 카드와 상세 헤더가 공유한다.
/// **파일**: lib/features/inquiry/domain/entities/inquiry.dart
///
/// 🔴 **와이어 값은 백엔드 enum 그대로 SCREAMING_SNAKE 다**(PLAN M6).
/// Dart 이름은 camelCase 라 `InquiryType.values.byName('PRODUCT_QNA')` 는 **반드시** 실패한다.
/// 직렬화·역직렬화는 오직 `wire` 값을 근거로 한다.
///
/// ⚠️ `replies`·`relatedOrder`·`relatedListing`·`replyCapability` 는 이 엔티티에 없다 —
/// 목록 응답에서 항상 null 이라(M1) 상세 전용 [InquiryDetail] 이 따로 들고 있다.

/// 문의 종류. 목록 화면의 탭 축이며 서버 조회 파라미터로 그대로 나간다.
///
/// ⚠️ **탭 후보와 라벨은 이 enum 이 정하지 않는다**(M2) — `GET /api/inquiries/types` 가 준
/// `InquiryTypeOption` 이 유일한 원천이다. 이 enum 은 파싱·전송용 값일 뿐이다.
enum InquiryType {
  productQna('PRODUCT_QNA'),
  callCenter('CALL_CENTER');

  const InquiryType(this.wire);

  /// 서버로 보내고 서버에서 받는 값. `name`(camelCase)이 아니다.
  final String wire;
}

/// 플랫폼 중립 문의 상태. 원문 상태는 [Inquiry.platformStatus] 에 그대로 남는다.
enum InquiryStatus {
  unanswered('UNANSWERED'),
  answered('ANSWERED'),
  closed('CLOSED'),
  stale('STALE');

  const InquiryStatus(this.wire);

  /// 서버로 보내고 서버에서 받는 값. `name`(camelCase)이 아니다.
  final String wire;
}

/// 답변 작성 주체. 상세 스레드의 좌/우 정렬과 배경색을 가른다.
///
/// ⚠️ 고객(질문자)은 여기 없다 — 문의 본문은 헤더이지 답변 행이 아니다(2609_23 D6).
enum InquiryAuthorRole {
  seller('SELLER'),
  csAgent('CS_AGENT');

  const InquiryAuthorRole(this.wire);

  /// 서버로 보내고 서버에서 받는 값. `name`(camelCase)이 아니다.
  final String wire;
}

/// 와이어 문자열 → [InquiryStatus].
///
/// 🔴 모르는 값(신규 코드·null) → [InquiryStatus.answered] + [debugPrint] (M7).
/// `unanswered` 로 폴백하면 답할 필요 없는 건이 '미답변' 으로 부풀어 칩 배지와 목록이
/// 거짓을 말하고, 사용자가 그 건을 열어 답을 쓰려다 서버 사유를 보고서야 안다.
/// 모르는 건은 **조용한 쪽**으로 떨어뜨린다(클레임의 `received` 폴백과 반대 방향인 것은 의도다).
///
/// ⚠️ 답변 버튼 노출은 이 폴백이 결정하지 않는다 — 그건 서버 `replyCapability` 가 소유한다(M3).
InquiryStatus parseInquiryStatus(String? v) {
  for (final s in InquiryStatus.values) {
    if (s.wire == v) return s;
  }
  debugPrint('[inquiry] unknown status: $v');
  return InquiryStatus.answered;
}

/// 와이어 문자열 → [InquiryType]. 모르는 값은 기본 탭인 상품문의로 둔다(목록이 통째로
/// 비는 것보다 낫다) + [debugPrint].
InquiryType parseInquiryType(String? v) {
  for (final t in InquiryType.values) {
    if (t.wire == v) return t;
  }
  debugPrint('[inquiry] unknown type: $v');
  return InquiryType.productQna;
}

/// 와이어 문자열 → [InquiryAuthorRole]. 모르는 값은 [InquiryAuthorRole.seller] +
/// [debugPrint] — 우리가 쓴 글로 보이는 쪽이 남의 글을 우리 것으로 오인하는 것보다 안전하다.
InquiryAuthorRole parseAuthorRole(String? v) {
  for (final r in InquiryAuthorRole.values) {
    if (r.wire == v) return r;
  }
  debugPrint('[inquiry] unknown author role: $v');
  return InquiryAuthorRole.seller;
}

/// 상태 → 한글 라벨. 목록 카드·상세·필터 칩이 공유하는 유일한 라벨표다.
///
/// ⚠️ 웹(`INQUIRY_STATUS_LABEL`)과 **같은 문자열**이어야 한다 — 같은 값을 두 화면이 다르게
/// 부르면 사용자는 둘 중 하나를 버그로 읽는다.
const inquiryStatusLabel = <InquiryStatus, String>{
  InquiryStatus.unanswered: '미답변',
  InquiryStatus.answered: '답변완료',
  InquiryStatus.closed: '종료',
  InquiryStatus.stale: '확인필요',
};

String getInquiryStatusLabel(InquiryStatus status) =>
    inquiryStatusLabel[status] ?? status.wire;

/// 상태 칩 후보. 웹(`INQUIRY_STATUS_FILTERS`)과 **같은 3개**다 —
/// `STALE` 은 칩으로 내지 않는다(로컬 강제 종결이라 사용자가 고를 축이 아니다).
/// 목록에 섞여 오면 라벨로는 보인다.
const inquiryStatusFilters = <InquiryStatus>[
  InquiryStatus.unanswered,
  InquiryStatus.answered,
  InquiryStatus.closed,
];

/// 문의 1건 (목록 응답).
///
/// ⚠️ 구매자 연락처·이메일·주소 필드를 만들지 말 것(M8) — 서버가 애초에 내려주지 않는다.
class Inquiry {
  final int id;

  /// 'COUPANG' 등. 표시용이며 화면은 이 값으로 분기하지 않는다(2609_23 D4).
  final String platform;

  /// ⚠️ 응답 필드는 `marketplaceAccountId` 인데 **조회 파라미터는 `accountId`** 다.
  /// 한쪽 이름으로 통일하지 말 것 — 응답에서 조용히 null 을 읽게 된다.
  final int? marketplaceAccountId;

  /// 별칭 미설정은 null 이 아니라 **빈 문자열**로 올 수 있다 — 표시는
  /// [inquiryChannelLabel] 로만 한다.
  final String? accountAlias;
  final int? sellerId;
  final String? sellerName;
  final InquiryType inquiryType;
  final InquiryStatus status;

  /// 플랫폼 원문 상태. 정보 손실 방지용 — **상세에만** 노출한다.
  final String? platformStatus;
  final String externalInquiryId;
  final String? externalOrderId;
  final String? externalItemId;
  final String? externalProductId;
  final int? productListingId;
  final int? orderItemId;
  final String? itemName;

  /// 문의 본문. 목록 카드는 2줄 말줄임, 상세는 전문을 그린다.
  final String? content;

  /// 고객센터 접수 분류. 상품문의에서는 null 이다.
  final String? category;
  final DateTime inquiredAt;
  final DateTime? answeredAt;

  /// false = 주문 라인 미연결(2609_23 D15). 상품문의는 주문 없는 질문이 다수라 **정상**이다 —
  /// 목록 카드에 경고 배지를 달지 말 것.
  final bool linked;

  const Inquiry({
    required this.id,
    required this.platform,
    required this.inquiryType,
    required this.status,
    required this.externalInquiryId,
    required this.inquiredAt,
    required this.linked,
    this.marketplaceAccountId,
    this.accountAlias,
    this.sellerId,
    this.sellerName,
    this.platformStatus,
    this.externalOrderId,
    this.externalItemId,
    this.externalProductId,
    this.productListingId,
    this.orderItemId,
    this.itemName,
    this.content,
    this.category,
    this.answeredAt,
  });
}

/// 채널 표시 문구 — 별칭이 없으면 웹(`channelOptionLabel`)과 같이 '채널 #{id}'.
///
/// ⚠️ 별칭은 빈 문자열로 올 수 있어 `??` 만으로는 빈 라벨이 된다.
String inquiryChannelLabel(int? accountId, String? alias) {
  final trimmed = alias?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return accountId == null ? '-' : '채널 #$accountId';
}
