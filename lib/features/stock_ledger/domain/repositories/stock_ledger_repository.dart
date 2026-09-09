import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/outbound_order.dart';
import '../entities/purchase_candidate.dart';
import '../entities/return_candidate.dart';
import '../entities/stock_balance.dart';
import '../entities/stock_enums.dart';
import '../entities/stock_movement.dart';

/// 실물 재고 원장 API (`/api/admin/stock/**`, PLAN 2609_28).
///
/// 판매자 축과 사유 코드를 가진 실물 원장이다(옛 재고 스택은 PLAN 2609_28 D21 로 제거됨).
abstract class StockLedgerRepository {
  /// (물품 × 판매자) 잔량. [sellerId] 생략 = 전 판매자, [keyword] = 상품명 부분일치.
  Future<Either<Failure, List<StockBalance>>> balances({
    int? productId,
    int? sellerId,
    String? keyword,
  });

  /// 원장 이력. [from]/[to] 는 YYYY-MM-DD, 생략 시 서버 기본 30일.
  Future<Either<Failure, List<StockMovement>>> movements({
    int? productId,
    int? sellerId,
    String? from,
    String? to,
  });

  /// 입고·반품입고·폐기·조정 1건 기록. 출고는 받지 않는다(400).
  ///
  /// [quantity] 는 **양수**로 보낸다 — 폐기 부호는 서버가 뒤집는다. 조정만 음수를 허용한다.
  Future<Either<Failure, StockMovement>> record({
    required int productId,
    int? sellerId,
    required StockMovementType movementType,
    required int quantity,
    StockReason? reason,
    String? reasonNote,
    double? unitPrice,
    int? orderClaimId,
    int? purchaseRecordId,
    required String movedOn,
  });

  /// 입고 대기 구매기록 (매입 입고 선택지).
  Future<Either<Failure, List<PurchaseCandidate>>> purchaseCandidates({int? productId});

  /// 반품 입고 대기 클레임 (반품입고 선택지).
  Future<Either<Failure, List<ReturnCandidate>>> returnCandidates();

  /// 출고 대상 주문 + 전개 실패 목록. [status] = `PAID` | `PREPARING` (생략 = 둘 다).
  Future<Either<Failure, OutboundResult>> outbound({int? sellerId, String? status});

  /// 출고 확인 1건 — 물품 1줄마다 개별 호출한다(D12).
  Future<Either<Failure, List<StockMovement>>> confirmOutbound({
    required int orderLineId,
    required int productId,
    required int quantity,
    required String movedOn,
  });
}
