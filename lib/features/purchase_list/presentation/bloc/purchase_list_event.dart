import 'purchase_list_state.dart' show PurchaseTab;

abstract class PurchaseListEvent {}

/// Page entry: loads the sellers and the purchase list (filter 「전체」).
///
/// ⚠️ The sellers feed the seller filter under the tabs, the intake card, the
/// manual add dialog and [판매자 바꾸기] (FEATURE_2610_09 D5 · D9 · D11 · D24).
class LoadPurchaseList extends PurchaseListEvent {}

/// One check-in (PLAN 2609_29 D1) — product × seller. A negative quantity is a
/// correction.
///
/// On success the current tab reloads and the server's stockRecorded travels in
/// the state as a one-time notice. Only one of total/unit is sent (PLAN 2609_28
/// D1/D2). recordStock is always true — the server writes stock only while the
/// stock link setting is on (FEATURE_2610_09 D65).
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

/// Replaces a manual line's quantity (1 or more, FEATURE_2610_09 D23). The
/// manual line's quantity field sends it; the list reloads on success.
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

/// Completed filter applied ([조회]): reloads with the processing-day range
/// (YYYY-MM-DD, empty = unbounded, FEATURE_2610_09 D63) and the page's seller
/// filter.
class ApplyCompletedFilter extends PurchaseListEvent {
  final String from;
  final String to;

  ApplyCompletedFilter({required this.from, required this.to});
}

/// Completed filter reset ([초기화]): back to today, then reload.
class ResetCompletedFilter extends PurchaseListEvent {}

/// 주문내역 동기화 버튼: 외부 마켓플레이스 동기화 후 재적재 → 목록 갱신.
///
/// ⚠️ 동기화는 항상 전체다(D11) — 별도 [재적재] 버튼은 없앴다(D12).
class SyncOrders extends PurchaseListEvent {}

/// Manual add: product + seller + quantity (>= 1) (FEATURE_2610_09 D11).
/// The list reloads on success.
class AddManualItem extends PurchaseListEvent {
  final int productId;
  final int sellerId;
  final int quantity;

  AddManualItem({
    required this.productId,
    required this.sellerId,
    required this.quantity,
  });
}

/// Seller filter under the tabs (FEATURE_2610_09 D1 · D5). null = 「전체」.
/// The current tab reloads; the other tab reloads on its next entry.
class ChangeSellerFilter extends PurchaseListEvent {
  final int? sellerId;

  ChangeSellerFilter({required this.sellerId});
}

/// [매입 완료] · [오늘 매입 안 함] on one share (FEATURE_2610_09 D57 · D61).
/// [status] = `PURCHASED` · `NOT_NEEDED` · `TOMORROW`.
class CheckShare extends PurchaseListEvent {
  final int productId;
  final int sellerId;
  final String status;

  CheckShare({
    required this.productId,
    required this.sellerId,
    required this.status,
  });
}

/// [완료 취소] · [되돌리기] of one share (FEATURE_2610_09 D62 · D67 · D79).
class CancelShareCheck extends PurchaseListEvent {
  final int checkId;

  CancelShareCheck({required this.checkId});
}

/// Moves a manual line to another seller (FEATURE_2610_09 D13 · D24). A seller
/// that already has one → the server's 409 text arrives as actionError (D26).
class ChangeManualSeller extends PurchaseListEvent {
  final int itemId;
  final int sellerId;

  ChangeManualSeller({required this.itemId, required this.sellerId});
}

/// [제거] — deletes the manual line (FEATURE_2610_09 D77).
class DeleteManualLine extends PurchaseListEvent {
  final int itemId;

  DeleteManualLine({required this.itemId});
}

/// The receipt popup saved a receipt, or the receipt sheet edited a receipt
/// header (FEATURE_2610_18 D46 · D100) — the current tab reloads like after a
/// check-in. The popup and the sheet call the use case themselves.
class ReceiptSaved extends PurchaseListEvent {}
