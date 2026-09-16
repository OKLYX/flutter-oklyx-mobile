/// 처리해야 할 일 1건 (GET /api/alerts, FEATURE_2609_51).
///
/// 🔴 저장된 알림이 아니다 — 결제완료 주문·미완결 클레임·미답변 문의를 조회 시점에 모아 만든
///    파생 값이다(D1). 일이 끝나면 다음 조회부터 사라진다. **확인·읽음 상태는 없다**(D2).
/// ❌ 목록을 손으로 비우는 수단(확인 버튼·읽음 표시)을 만들지 말 것.
library;

/// 알림의 출처 (서버 `AlertType` 과 1:1).
///
/// 🔴 서버 응답은 **대문자 문자열**(`ORDER`)이다 — 조회 파라미터도 대문자로 보낸다.
enum AlertType {
  order('ORDER'),
  claim('CLAIM'),
  inquiry('INQUIRY');

  /// 서버가 주고받는 값. 화면 라벨이 아니다.
  final String wireValue;

  const AlertType(this.wireValue);

  /// 모르는 값이면 null — 호출부(모델)가 **그 행을 건너뛴다**(한 줄 때문에 화면이 죽지 않게).
  static AlertType? fromWire(String? value) {
    if (value == null) return null;
    for (final type in AlertType.values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

/// 알림 목록의 행 하나.
class AlertFeedItem {
  final AlertType alertType;

  /// ORDER = 주문 id(라인 id 아님, D5) · CLAIM = 클레임 id · INQUIRY = 문의 id.
  final int refId;

  /// ORDER 의 주문번호. 다른 타입은 참고용이다.
  final String? externalOrderId;

  /// 'COUPANG' 등 플랫폼 코드. 화면은 `platformLabel()` 로 한글 라벨을 만든다.
  final String platform;

  final String? sellerName;

  /// ORDER 는 **대표 상품 1개**(첫 라인).
  final String? itemName;

  /// ORDER 의 상품(라인) 수 — 화면이 `상품 3개` 로 그린다.
  /// ⚠️ 2026-09-16 이후 Drawer 배지도 **주문 단위**(`paidOrders`)라 단위 차이는 없다. 남은 차이는 기간뿐.
  final int? itemCount;

  /// 클레임=사유 · 문의=본문 앞부분 · 주문=null.
  final String? detail;

  /// ORDER=주문일 · CLAIM=접수일 · INQUIRY=문의일. 정렬 기준이다.
  ///
  /// 🔴 세 소스 모두 마켓이 준 **KST 벽시계**다 — 상대 표기는 `formatMarketRelativeTime` 을 쓴다.
  ///    `formatRelativeTime`(서버 낙인 UTC 전용)을 쓰면 9시간 어긋난다(D8).
  final String? occurredAt;

  /// 'RETURN' | 'EXCHANGE' — 클레임일 때만 채워진다.
  final String? claimType;

  const AlertFeedItem({
    required this.alertType,
    required this.refId,
    required this.platform,
    this.externalOrderId,
    this.sellerName,
    this.itemName,
    this.itemCount,
    this.detail,
    this.occurredAt,
    this.claimType,
  });
}

/// 알림 목록 한 장 (PLAN D12 — 시각 커서 페이징).
class AlertFeedPage {
  final List<AlertFeedItem> items;

  /// 🔴 **불투명 문자열**이다 — 만들거나 해석하지 말고 받은 값을 그대로 돌려보낸다.
  ///    null 이면 마지막 장이다.
  final String? nextCursor;

  const AlertFeedPage({required this.items, this.nextCursor});
}
