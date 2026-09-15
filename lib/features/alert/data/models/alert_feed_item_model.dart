import '../../domain/entities/alert_feed_item.dart';

/// `GET /api/alerts` 응답 → [AlertFeedItem] / [AlertFeedPage].
///
/// ⚠️ 서버 enum 은 **대문자 문자열**(`ORDER`)이다.
/// 🔴 모르는 `alertType` 이 오면 예외를 던지지 않고 **그 행을 건너뛴다** — 서버에 항목이 하나
///    늘었다고 화면 전체가 죽으면 안 된다(AlertType 은 뒤에 값이 붙는다).
class AlertFeedItemModel extends AlertFeedItem {
  const AlertFeedItemModel({
    required super.alertType,
    required super.refId,
    required super.platform,
    super.externalOrderId,
    super.sellerName,
    super.itemName,
    super.itemCount,
    super.detail,
    super.occurredAt,
    super.claimType,
  });

  /// 알 수 없는 타입·id 없는 행이면 null(호출자가 거른다).
  static AlertFeedItemModel? tryFromJson(Map<String, dynamic> json) {
    final type = AlertType.fromWire(json['alertType'] as String?);
    final refId = (json['refId'] as num?)?.toInt();
    if (type == null || refId == null) return null;
    return AlertFeedItemModel(
      alertType: type,
      refId: refId,
      platform: (json['platform'] as String?) ?? '',
      externalOrderId: json['externalOrderId'] as String?,
      sellerName: json['sellerName'] as String?,
      itemName: json['itemName'] as String?,
      itemCount: (json['itemCount'] as num?)?.toInt(),
      detail: json['detail'] as String?,
      occurredAt: json['occurredAt'] as String?,
      claimType: json['claimType'] as String?,
    );
  }
}

/// 목록 + 다음 커서 한 쌍.
class AlertFeedPageModel extends AlertFeedPage {
  const AlertFeedPageModel({required super.items, super.nextCursor});

  factory AlertFeedPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <AlertFeedItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map<String, dynamic>) continue;
        final item = AlertFeedItemModel.tryFromJson(raw);
        if (item != null) items.add(item);
      }
    }
    return AlertFeedPageModel(
      items: items,
      // 🔴 해석하지 않는다 — 다음 장 요청에 그대로 실어 보낸다.
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
