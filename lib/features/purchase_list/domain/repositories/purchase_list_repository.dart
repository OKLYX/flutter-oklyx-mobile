import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';
import '../entities/purchase_list_result.dart';
import '../entities/purchase_record.dart';
import '../entities/purchase_record_result.dart';

abstract class PurchaseListRepository {
  /// Active purchase list (items + unmapped orders). 항상 전체다(PLAN 2609_29 D11).
  Future<Either<Failure, PurchaseListResult>> getList();

  /// Re-extract from 결제완료(PAID) orders (idempotent); returns the refreshed result.
  Future<Either<Failure, PurchaseListResult>> extract();

  /// Completed purchases (remainingQty <= 0 && purchasedQty > 0).
  /// 구매일 기간([from]/[to], YYYY-MM-DD)만으로 거른다 — null = 전체(D21).
  Future<Either<Failure, List<PurchaseListItem>>> getCompleted(
    String? from,
    String? to,
  );

  /// 입고 1회 — 물품 × 판매자에 귀속된다(D1·D3). [quantity] 음수는 정정이다.
  ///
  /// Pass at most one of [totalAmount]/[unitPrice] — the server derives the other
  /// and rejects both-present (PLAN 2609_28 D1/D2). Both null = amount unknown.
  /// 응답의 stockRecorded=false 는 재고가 반영되지 않았다는 뜻이다(D17·D19).
  Future<Either<Failure, PurchaseRecordResult>> recordPurchase(
    int productId,
    int sellerId,
    String purchasedOn,
    int quantity, {
    double? totalAmount,
    double? unitPrice,
    bool reflectToBasePrice = true,
    bool recordStock = true,
  });

  /// 그 물품의 최근 구매이력 — 판매자 무관, 최신순 [limit]건(D9).
  Future<Either<Failure, List<PurchaseRecord>>> recentPurchases(
    int productId, {
    int limit = 5,
  });

  /// Replace the manual quantity of a line with an absolute value (0+).
  Future<Either<Failure, void>> adjustManualQty(int itemId, int manualQty);

  /// Add (or accumulate) a manual line for a product. [quantity] >= 1.
  Future<Either<Failure, void>> addManual(int productId, int quantity);
}
