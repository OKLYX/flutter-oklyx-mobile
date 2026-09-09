import 'purchase_list_state.dart' show PurchaseTab;

abstract class PurchaseListEvent {}

/// 페이지 진입 시: 판매자 목록 + 구매목록 로드.
///
/// ⚠️ 판매자 목록은 **입고 카드 드롭다운**이 쓴다 — 툴바 필터는 없어졌다(PLAN 2609_29 D11).
class LoadPurchaseList extends PurchaseListEvent {}

/// 상품 카드 펼침/접힘 토글 (재조회 없음)
class ToggleExpand extends PurchaseListEvent {
  final int productId;

  ToggleExpand({required this.productId});
}

/// 입고 1회 (PLAN 2609_29 D1) — 물품 × 판매자. 수량 음수 허용 = 정정.
///
/// 성공 시 현재 탭 기준으로 목록을 재조회하고, 서버가 준 stockRecorded 를
/// 1회성 안내로 상태에 싣는다. 금액은 총액/단가 중 하나만 채워 보낸다(PLAN 2609_28 D1/D2).
/// recordStock 은 항상 true 다 — 화면 체크박스는 체크 + 비활성(D19).
class RecordPurchase extends PurchaseListEvent {
  final int productId;
  final int sellerId;
  final String purchasedOn; // YYYY-MM-DD
  final int quantity;
  final double? totalAmount;
  final double? unitPrice;
  final bool reflectToBasePrice;

  RecordPurchase({
    required this.productId,
    required this.sellerId,
    required this.purchasedOn,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
  });
}

/// 입고 결과 안내(stockRecorded) 소비 완료 — SnackBar 를 띄운 뒤 곧바로 보낸다.
///
/// ⚠️ 안 보내면 다음 리빌드에 같은 안내가 또 뜬다.
class ClearStockNotice extends PurchaseListEvent {}

/// 라인의 수동수량을 절대값으로 교체. 성공 시 목록 재조회.
///
/// ⚠️ 주문 줄에는 입력 컨트롤이 없어(D7) 현재 이 이벤트를 쏘는 화면이 없다 —
/// 서버 엔드포인트(PATCH /items/{itemId})와 배선은 그대로 살려둔다.
class AdjustManualQty extends PurchaseListEvent {
  final int itemId;
  final int manualQty;

  AdjustManualQty({required this.itemId, required this.manualQty});
}

/// 탭 전환 (구매목록 / 구매완료내역). completed 미로드 시 지연 로드.
class SwitchTab extends PurchaseListEvent {
  final PurchaseTab tab;

  SwitchTab({required this.tab});
}

/// 완료 탭 상품 카드 펼침/접힘 토글.
class ToggleExpandCompleted extends PurchaseListEvent {
  final int productId;

  ToggleExpandCompleted({required this.productId});
}

/// 완료내역 필터 적용 ('조회' 버튼): 구매일 기간(YYYY-MM-DD, 빈 값=전체)으로 재조회.
/// 판매자 필터는 없다(D21).
class ApplyCompletedFilter extends PurchaseListEvent {
  final String from;
  final String to;

  ApplyCompletedFilter({required this.from, required this.to});
}

/// 완료내역 필터 초기화 ('초기화' 버튼): 구매일 오늘로 되돌린 뒤 재조회.
class ResetCompletedFilter extends PurchaseListEvent {}

/// 주문내역 동기화 버튼: 외부 마켓플레이스 동기화 후 재적재 → 목록 갱신.
///
/// ⚠️ 동기화는 항상 전체다(D11) — 별도 [재적재] 버튼은 없앴다(D12).
class SyncOrders extends PurchaseListEvent {}

/// 수동항목 추가: 상품 + 수량(>=1)으로 수동 라인 추가. 성공 시 목록 재조회.
class AddManualItem extends PurchaseListEvent {
  final int productId;
  final int quantity;

  AddManualItem({required this.productId, required this.quantity});
}
