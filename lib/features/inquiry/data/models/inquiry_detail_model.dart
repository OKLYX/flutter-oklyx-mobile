import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_detail.dart';
import 'inquiry_model.dart';

/// `GET /api/inquiries/{id}` 응답 → [InquiryDetail].
///
/// 공통 필드는 [InquiryModel] 이 그대로 파싱한다 — 같은 응답 스키마를 두 벌 매핑하지 않는다.
/// 상세 전용 필드(`replies`·`relatedOrder`·`relatedListing`·`replyCapability`)만 여기서 읽는다.
class InquiryDetailModel extends InquiryDetail {
  const InquiryDetailModel({
    required super.inquiry,
    super.replies,
    super.relatedOrder,
    super.relatedListing,
    super.replyCapability,
  });

  factory InquiryDetailModel.fromJson(Map<String, dynamic> json) =>
      InquiryDetailModel(
        inquiry: InquiryModel.fromJson(json),
        replies: _parseReplies(json['replies']),
        relatedOrder: _parseOrder(json['relatedOrder']),
        relatedListing: _parseListing(json['relatedListing']),
        replyCapability: _parseCapability(json['replyCapability']),
      );

  /// 서버가 `replied_at ASC` 로 정렬해 준다 — 여기서 다시 정렬하지 않는다.
  static List<InquiryReply> _parseReplies(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => InquiryReply(
            id: (e['id'] as num?)?.toInt() ?? 0,
            authorRole: parseAuthorRole(e['authorRole'] as String?),
            externalReplyId: e['externalReplyId'] as String?,
            parentExternalReplyId: e['parentExternalReplyId'] as String?,
            authorName: e['authorName'] as String?,
            content: e['content'] as String?,
            transferStatus: e['transferStatus'] as String?,
            repliedAt: DateTime.tryParse(e['repliedAt'] as String? ?? ''),
          ),
        )
        .toList();
  }

  static RelatedOrder? _parseOrder(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return RelatedOrder(
      externalOrderId: raw['externalOrderId'] as String?,
      paidAt: DateTime.tryParse(raw['paidAt'] as String? ?? ''),
      ordererName: raw['ordererName'] as String?,
      receiverName: raw['receiverName'] as String?,
      lines: _parseLines(raw['lines']),
    );
  }

  /// ⚠️ `status` 는 **문자열 그대로** 둔다 — 표시할 때만 주문 기능의
  /// `getOrderStatusLabel(orderStatusFrom(status))` 를 쓴다(문의 전용 상태표 금지).
  static List<RelatedOrderLine> _parseLines(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => RelatedOrderLine(
            orderCount: (e['orderCount'] as num?)?.toInt() ?? 0,
            cancelCount: (e['cancelCount'] as num?)?.toInt() ?? 0,
            isInquiryLine: e['isInquiryLine'] == true,
            orderItemId: (e['orderItemId'] as num?)?.toInt(),
            itemName: e['itemName'] as String?,
            status: e['status'] as String?,
          ),
        )
        .toList();
  }

  static RelatedListing? _parseListing(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return RelatedListing(
      productListingId: (raw['productListingId'] as num?)?.toInt(),
      listingName: raw['listingName'] as String?,
      optionName: raw['optionName'] as String?,
    );
  }

  /// ⚠️ null 은 "모른다" 이지 "가능하다" 가 아니다 — 03 의 컴포저는 null 이면 아무것도
  /// 그리지 않는다(PLAN M3).
  static ReplyCapability? _parseCapability(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ReplyCapability(
      canReply: raw['canReply'] == true,
      minLength: (raw['minLength'] as num?)?.toInt() ?? 0,
      maxLength: (raw['maxLength'] as num?)?.toInt() ?? 0,
      once: raw['once'] == true,
      reason: raw['reason'] as String?,
      parentReplyId: raw['parentReplyId'] as String?,
    );
  }
}
