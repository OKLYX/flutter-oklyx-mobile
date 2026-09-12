import '../../domain/entities/inquiry.dart';

/// `GET /api/inquiries` 응답 1건 → [Inquiry].
///
/// 관례는 `ClaimModel` 과 같다 — 모델이 엔티티를 상속하고 `fromJson` 만 갖는다.
///
/// 🔴 `status`·`inquiryType` 은 **와이어 값(SCREAMING_SNAKE)** 이다.
/// `InquiryStatus.values.byName(...)` 은 `PRODUCT_QNA`·`UNANSWERED` 에서 반드시 실패하므로
/// [parseInquiryStatus] / [parseInquiryType] 을 거친다(PLAN M6).
class InquiryModel extends Inquiry {
  const InquiryModel({
    required super.id,
    required super.platform,
    required super.inquiryType,
    required super.status,
    required super.externalInquiryId,
    required super.inquiredAt,
    required super.linked,
    super.marketplaceAccountId,
    super.accountAlias,
    super.sellerId,
    super.sellerName,
    super.platformStatus,
    super.externalOrderId,
    super.externalItemId,
    super.externalProductId,
    super.productListingId,
    super.orderItemId,
    super.itemName,
    super.content,
    super.category,
    super.answeredAt,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) => InquiryModel(
        id: (json['id'] as num).toInt(),
        platform: json['platform'] as String? ?? '',
        inquiryType: parseInquiryType(json['inquiryType'] as String?),
        status: parseInquiryStatus(json['status'] as String?),
        externalInquiryId: json['externalInquiryId'] as String? ?? '',
        // 서버는 ISO LocalDateTime 문자열을 준다. 파싱 실패해도 화면이 죽지 않게
        // epoch 로 떨어뜨린다(ClaimModel 과 같은 자세).
        inquiredAt: DateTime.tryParse(json['inquiredAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        linked: json['linked'] as bool? ?? false,
        marketplaceAccountId: (json['marketplaceAccountId'] as num?)?.toInt(),
        accountAlias: json['accountAlias'] as String?,
        sellerId: (json['sellerId'] as num?)?.toInt(),
        sellerName: json['sellerName'] as String?,
        platformStatus: json['platformStatus'] as String?,
        externalOrderId: json['externalOrderId'] as String?,
        externalItemId: json['externalItemId'] as String?,
        externalProductId: json['externalProductId'] as String?,
        productListingId: (json['productListingId'] as num?)?.toInt(),
        orderItemId: (json['orderItemId'] as num?)?.toInt(),
        itemName: json['itemName'] as String?,
        content: json['content'] as String?,
        category: json['category'] as String?,
        answeredAt: DateTime.tryParse(json['answeredAt'] as String? ?? ''),
      );
}
