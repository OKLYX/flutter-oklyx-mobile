import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

/// Settlement ledger API (FEATURE_2610_20 / D18 · D19). Lookups read the local
/// DB; `sync*` ask the market and are called from buttons only (D19). A failure
/// carries the HTTP status in `ServerFailure.statusCode` (403 = not admin —
/// D20, 429 = market rate limit — D24).
abstract class SettlementRepository {
  Future<Either<Failure, List<PayoutSummary>>> getPayouts(
      {int? sellerId, int? accountId, String? from, String? to});

  Future<Either<Failure, List<PayoutSummary>>> getPayoutsByRecognition({
    required String from,
    required String to,
    int? sellerId,
  });

  Future<Either<Failure, List<SaleMonthSettlement>>> getSaleMonthSettlements({
    required int accountId,
    required String from,
    required String to,
  });

  /// This month's payout sums — the dashboard payout card (FEATURE_2610_29 /
  /// D30). 🔴 Its date basis differs from [getPayouts] (confirmed payout date,
  /// else scheduled).
  Future<Either<Failure, SettlementMonthSummary>> getMonthSummary(
      {int? sellerId});

  Future<Either<Failure, ReconReport>> getReport(int payoutId);

  Future<Either<Failure, List<ReconLineView>>> getPayoutLines(int payoutId,
      {String? label, bool? unmatched});

  Future<Either<Failure, Uint8List>> exportReport(int payoutId);

  Future<Either<Failure, SettlementSyncResult>> syncSettlement(
      {int? accountId, int? sellerId});

  Future<Either<Failure, PayoutSyncResult>> syncPayouts(
      {int? accountId, String? month});

  Future<Either<Failure, SettlementSyncResult>> syncRevenuePeriod({
    required int accountId,
    required String from,
    required String to,
  });

  Future<Either<Failure, List<SettlementSyncTarget>>> getSyncTargets(
      {int? sellerId});

  Future<Either<Failure, Unit>> markPaid(int payoutId, String paidOn);

  Future<Either<Failure, Unit>> unmarkPaid(int payoutId);

  Future<Either<Failure, List<FirstMonthQuestion>>> getFirstMonthQuestions();

  Future<Either<Failure, Unit>> answerFirstMonth(int linkId,
      {required bool charged});
}
