import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';
import '../entities/purchase_list_result.dart';
import '../entities/purchase_record.dart';
import '../entities/purchase_record_result.dart';

abstract class PurchaseListRepository {
  /// Purchase list tab (rows to buy + 「오늘 넘김」 + unmapped orders).
  /// [sellerId] null = 「전체」 (FEATURE_2610_09 D1 · D4).
  Future<Either<Failure, PurchaseListResult>> getList(int? sellerId);

  /// Re-extract from 결제완료(PAID) orders (idempotent); returns the refreshed result.
  Future<Either<Failure, PurchaseListResult>> extract();

  /// Completed rows (every share processed, FEATURE_2610_09 D57 · D78).
  /// Processing-day range ([from]/[to], YYYY-MM-DD, null = unbounded) and
  /// [sellerId] (null = 「전체」).
  Future<Either<Failure, List<PurchaseListItem>>> getCompleted(
    String? from,
    String? to,
    int? sellerId,
  );

  /// One check-in, attributed to product × seller (D1 · D3). A negative
  /// [quantity] is a correction.
  ///
  /// Pass at most one of [totalAmount]/[unitPrice] — the server derives the other
  /// and rejects both-present (PLAN 2609_28 D1/D2). Both null = amount unknown.
  /// stockRecorded=false in the response = no stock written: a negative
  /// correction (D17) or the stock link setting is off (FEATURE_2610_09 D65).
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

  /// Recent purchases of a product, newest first, [limit] rows; [sellerId]
  /// null = every seller (FEATURE_2610_09 D7 · D25).
  Future<Either<Failure, List<PurchaseRecord>>> recentPurchases(
    int productId, {
    int limit = 5,
    int? sellerId,
  });

  /// Replace a manual line's quantity with an absolute value (1+).
  Future<Either<Failure, void>> adjustManualQty(int itemId, int manualQty);

  /// Add (or accumulate) the (product × seller) manual line. [quantity] >= 1.
  Future<Either<Failure, void>> addManual(
    int productId,
    int sellerId,
    int quantity,
  );

  /// Move a manual line to another seller; 409 when that seller already has
  /// one (FEATURE_2610_09 D13 · D26).
  Future<Either<Failure, void>> changeManualSeller(int itemId, int sellerId);

  /// Delete a manual line (FEATURE_2610_09 D77).
  Future<Either<Failure, void>> deleteManual(int itemId);

  /// [매입 완료] · [오늘 매입 안 함] on one share. [status] = PURCHASED ·
  /// NOT_NEEDED · TOMORROW (FEATURE_2610_09 D57 · D61).
  Future<Either<Failure, void>> check(
      int productId, int sellerId, String status);

  /// [완료 취소] · [되돌리기] (FEATURE_2610_09 D62 · D67 · D79).
  Future<Either<Failure, void>> cancelCheck(int checkId);

  /// Stock link setting (FEATURE_2610_09 D65 · D71).
  Future<Either<Failure, bool>> getStockLinked();
}
