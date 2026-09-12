import 'inquiry.dart';

/// 고객문의 **단건** 도메인 — `GET /api/inquiries/{id}` (PLAN M1).
///
/// **용도**: 상세 화면이 그리는 스레드·관련 주문·관련 상품·답변 가능 여부.
/// **파일**: lib/features/inquiry/domain/entities/inquiry_detail.dart
///
/// 🔴 목록 엔티티 [Inquiry] 를 확장하지 않는다 — [InquiryReply]·[RelatedOrder] 등은
/// **단건 조회에서만** 채워지므로(목록은 항상 null) 한 클래스에 담으면 "값이 없는 필드"가
/// 화면 코드 전체에 퍼진다. 공통 필드는 [inquiry] 로 그대로 재사용한다.
class InquiryDetail {
  /// 목록과 같은 공통 필드 전부. 상세 헤더가 읽는다.
  final Inquiry inquiry;

  /// 답변 스레드. 서버가 `replied_at ASC` 로 정렬해 준다 — 클라이언트가 다시 정렬하지 않는다.
  final List<InquiryReply> replies;

  /// 주문 미연결이면 null. 상품문의는 주문 없는 질문이 다수라 **정상**이다(2609_23 D15).
  final RelatedOrder? relatedOrder;

  /// 셀(판매상품) 미연결이면 null. [relatedOrder] 가 없을 때의 대체 정보다.
  final RelatedListing? relatedListing;

  /// 답변 가능 여부·제약(M3). ⚠️ 03(답변 작성)이 쓴다 — 02 는 파싱만 하고 화면에 쓰지 않는다.
  final ReplyCapability? replyCapability;

  const InquiryDetail({
    required this.inquiry,
    this.replies = const [],
    this.relatedOrder,
    this.relatedListing,
    this.replyCapability,
  });
}

/// 답변 1건 (스레드 요소).
class InquiryReply {
  final int id;
  final String? externalReplyId;
  final String? parentExternalReplyId;

  /// SELLER = 오른쪽 말풍선, CS_AGENT = 왼쪽 말풍선.
  final InquiryAuthorRole authorRole;

  /// 쿠팡 상담사 이름 — 고객 PII 가 아니다(2609_23 D13).
  final String? authorName;
  final String? content;

  /// 고객센터 이관 상태 **원문**. 화면에 쓰지 않는다(디버깅용 보관).
  final String? transferStatus;
  final DateTime? repliedAt;

  const InquiryReply({
    required this.id,
    required this.authorRole,
    this.externalReplyId,
    this.parentExternalReplyId,
    this.authorName,
    this.content,
    this.transferStatus,
    this.repliedAt,
  });
}

/// 관련 주문 — 같은 주문번호의 **모든 라인**(합포장 포함)을 담는다.
///
/// ⚠️ 금액 필드가 없다. 서버가 내려주지 않으므로 화면에도 금액을 그리지 않는다.
/// 🔴 연락처·주소는 없다(M8) — 이름(주문자·수취인)만 실린다.
class RelatedOrder {
  final String? externalOrderId;
  final DateTime? paidAt;
  final String? ordererName;
  final String? receiverName;
  final List<RelatedOrderLine> lines;

  const RelatedOrder({
    this.externalOrderId,
    this.paidAt,
    this.ordererName,
    this.receiverName,
    this.lines = const [],
  });
}

/// 주문 라인 1개.
class RelatedOrderLine {
  final int? orderItemId;
  final String? itemName;
  final int orderCount;
  final int cancelCount;

  /// 🔴 중립 `OrderStatus` **이름 문자열** 그대로 둔다(파싱하지 않는다). 표시할 때만 주문
  /// 기능의 기존 함수 2개를 쓴다 — `getOrderStatusLabel(orderStatusFrom(status))`.
  /// 문의 기능에 자체 상태 enum·라벨 맵을 만들지 말 것(같은 주문이 화면마다 다른 라벨이 된다).
  final String? status;

  /// true = 이 문의가 가리키는 라인. 패널에서 강조한다.
  final bool isInquiryLine;

  const RelatedOrderLine({
    required this.orderCount,
    required this.cancelCount,
    required this.isInquiryLine,
    this.orderItemId,
    this.itemName,
    this.status,
  });
}

/// 관련 상품(셀) — `externalItemId`(vendorItemId)로 찾은 판매상품.
class RelatedListing {
  final int? productListingId;
  final String? listingName;
  final String? optionName;

  const RelatedListing({
    this.productListingId,
    this.listingName,
    this.optionName,
  });
}

/// 답변 가능 여부·제약 (PLAN M3 / 2609_23 D5).
///
/// 🔴 **판정은 서버 한 곳**(`InquiryReplyPolicy`)이다. 유형별 규칙(상품문의 1자~ ·
/// 고객센터 2자~ · 부모 답변 필수)을 앱이 재구현하면 웹과 앱이 서로 다른 답을 주고
/// 한쪽에서만 전송이 400 난다. [reason] 도 서버가 완성한 문장이라 코드→문구 맵을 두지 않는다.
class ReplyCapability {
  final bool canReply;

  /// [canReply] 가 false 일 때만 채워지는 **사용자 노출 문구**.
  final String? reason;
  final int minLength;
  final int maxLength;

  /// true = 되돌릴 수 없음 → 03 이 확인 `AlertDialog` 를 건다(M11).
  final bool once;

  /// 고객센터 전용. 서버가 고른 값이며 전송 시 서버가 자기 값을 다시 고른다.
  final String? parentReplyId;

  const ReplyCapability({
    required this.canReply,
    required this.minLength,
    required this.maxLength,
    required this.once,
    this.reason,
    this.parentReplyId,
  });
}
