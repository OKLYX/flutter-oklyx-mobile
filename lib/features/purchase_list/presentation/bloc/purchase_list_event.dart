import 'purchase_list_state.dart' show PurchaseTab;

abstract class PurchaseListEvent {}

/// 페이지 진입 시: 판매자 목록 + 전체 구매목록 로드 (프론트 초기 useEffect와 동일)
class LoadPurchaseList extends PurchaseListEvent {}

/// 판매자 드롭다운 변경 (null = 전체) → 해당 판매자 기준으로 목록 재조회
class SelectSeller extends PurchaseListEvent {
  final int? sellerId;

  SelectSeller({this.sellerId});
}

/// 재적재 버튼: ACCEPT 주문 기준으로 목록 재생성 (수동수량/구매기록 유지)
class ExtractPurchaseList extends PurchaseListEvent {}

/// 상품 카드 펼침/접힘 토글 (재조회 없음)
class ToggleExpand extends PurchaseListEvent {
  final int productId;

  ToggleExpand({required this.productId});
}

/// 라인에 구매 기록 (수량 음수 허용 = 정정). 성공 시 목록 재조회.
class RecordPurchase extends PurchaseListEvent {
  final int itemId;
  final String purchasedOn; // YYYY-MM-DD
  final int quantity;

  RecordPurchase({
    required this.itemId,
    required this.purchasedOn,
    required this.quantity,
  });
}

/// 라인의 수동수량을 절대값으로 교체. 성공 시 목록 재조회.
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

/// 완료 탭 상품 카드 펼침/접힘 토글 (읽기전용).
class ToggleExpandCompleted extends PurchaseListEvent {
  final int productId;

  ToggleExpandCompleted({required this.productId});
}

/// 주문동기화 버튼: 외부 마켓플레이스 동기화 후 재적재 → 목록 갱신.
class SyncOrders extends PurchaseListEvent {}

/// 수동항목 추가: 상품 + 수량(>=1)으로 수동 라인 추가. 성공 시 목록 재조회.
class AddManualItem extends PurchaseListEvent {
  final int productId;
  final int quantity;

  AddManualItem({required this.productId, required this.quantity});
}
