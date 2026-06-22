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
