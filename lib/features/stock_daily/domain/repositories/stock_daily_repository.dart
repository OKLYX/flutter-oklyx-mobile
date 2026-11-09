import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import '../entities/stock_daily.dart';

/// 「일별 입출고 내역」 data (FEATURE_2610_19 D119 · D121 · FEATURE_2611_01 D2 ·
/// D7).
abstract class StockDailyRepository {
  Future<Either<Failure, StockDaily>> getDaily(String date);

  Future<Either<Failure, Unit>> assign(
    String movedOn,
    File photo,
    CreateReceiptParams params,
  );

  /// 「영수증 없이 판매자 정하기」 — [mode] `RECEIPT_LATER` or `NO_RECEIPT`.
  Future<Either<Failure, Unit>> assignWithoutReceipt(
    String movedOn,
    String mode,
    int sellerId,
    List<ReceiptLineParams> lines,
  );

  /// 「판매자 바꾸기」 of incoming rows and 「영수증 없음」 shares.
  Future<Either<Failure, Unit>> changeSeller(
    int sellerId,
    List<int> movementIds,
    List<int> shareRecordIds,
  );

  /// 「매입가 넣기」 of checked rows and shares (FEATURE_2611_16 D2 · D7) —
  /// [photo] null = amounts only · [cardId] = the new receipt's card.
  Future<Either<Failure, Unit>> retypePrices(
    String movedOn,
    File? photo,
    int? cardId,
    List<PurchasePriceLine> lines,
  );

  /// The row sheet's one save (FEATURE_2611_17 D5) — [photo] null = none.
  Future<Either<Failure, Unit>> editRow(
    String movedOn,
    File? photo,
    DailyRowEdit edit,
  );

  /// The 「날짜 바꾸기」 sheet (FEATURE_2611_21 D9): one row to [newMovedOn].
  Future<Either<Failure, Unit>> moveDate(int movementId, String newMovedOn);

  /// That day's receipts for the row sheet (FEATURE_2611_17 D23).
  Future<Either<Failure, List<DayReceipt>>> getDayReceipts(String date);
}
