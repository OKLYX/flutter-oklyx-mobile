import '../../domain/entities/stock_enums.dart';

/// 재고 원장 이벤트 (PLAN 2609_28).
///
/// 세 화면(입고·조정 / 출고 확인 / 재고 조회)이 **한 BLoC** 을 공유한다 —
/// 화면마다 BLoC 을 만들면 사유 라벨과 에러 처리가 갈린다.
abstract class StockLedgerEvent {}

/// 입고·조정 화면 진입: 판매자 + 입고 대기 구매 + 반품 대기 + 최근 이력.
class LoadEntryData extends StockLedgerEvent {}

/// 재고 조회 화면: (물품 × 판매자) 잔량. [keyword] = 상품명 부분일치, [sellerId] null = 전체.
class LoadBalances extends StockLedgerEvent {
  final String? keyword;
  final int? sellerId;

  LoadBalances({this.keyword, this.sellerId});
}

/// 원장 이력 조회. 잔량 행 탭(물품별) · 입고 기록 후 최근 이력 갱신에 쓴다.
class LoadMovements extends StockLedgerEvent {
  final int? productId;
  final int? sellerId;

  /// YYYY-MM-DD. 생략하면 서버 기본 30일.
  final String? from;
  final String? to;

  LoadMovements({this.productId, this.sellerId, this.from, this.to});
}

/// 입고·반품입고·폐기·조정 1건 기록.
///
/// ⚠️ [quantity] 는 양수로 보낸다 — 폐기 부호는 서버가 뒤집는다(조정만 음수 허용).
class RecordMovement extends StockLedgerEvent {
  final int productId;
  final int? sellerId;
  final StockMovementType movementType;
  final int quantity;
  final StockReason? reason;
  final String? reasonNote;
  final double? unitPrice;
  final int? orderClaimId;
  final int? purchaseRecordId;
  final String movedOn;

  RecordMovement({
    required this.productId,
    this.sellerId,
    required this.movementType,
    required this.quantity,
    this.reason,
    this.reasonNote,
    this.unitPrice,
    this.orderClaimId,
    this.purchaseRecordId,
    required this.movedOn,
  });
}

/// 출고 확인 화면: 나갈 주문 + 전개 실패 목록. [sellerId] null = 전 판매자.
class LoadOutbound extends StockLedgerEvent {
  final int? sellerId;

  LoadOutbound({this.sellerId});
}

/// 출고 확인 1건 (물품 1줄 = 요청 1회, D12).
///
/// ⚠️ 성공해도 전체 재조회를 하지 않는다 — 그 줄의 확인 수량만 올린다(스크롤이 튄다).
class ConfirmOutbound extends StockLedgerEvent {
  final int orderLineId;
  final int productId;
  final int quantity;
  final String movedOn;

  ConfirmOutbound({
    required this.orderLineId,
    required this.productId,
    required this.quantity,
    required this.movedOn,
  });
}

/// 일회성 안내(SnackBar) 소비 완료 — 안 보내면 다음 리빌드에 또 뜬다.
class ClearStockLedgerNotice extends StockLedgerEvent {}
