import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/repositories/settlement_repository.dart';

/// Settlement use case (FEATURE_2610_20) — shared by the 「정산 내역」 list · detail,
/// the 「매출」 screens and the dashboard payout card (FEATURE_2610_29).
class SettlementUseCase {
  final SettlementRepository repository;

  SettlementUseCase({required this.repository});

  Future<Either<Failure, List<PayoutSummary>>> getPayouts(
          {int? sellerId, int? accountId, String? from, String? to}) =>
      repository.getPayouts(
          sellerId: sellerId, accountId: accountId, from: from, to: to);

  /// Revenue-recognition-month axis — the sales screen only.
  Future<Either<Failure, List<PayoutSummary>>> getPayoutsByRecognition({
    required String from,
    required String to,
    int? sellerId,
  }) =>
      repository.getPayoutsByRecognition(
          from: from, to: to, sellerId: sellerId);

  Future<Either<Failure, List<SaleMonthSettlement>>> getSaleMonthSettlements({
    required int accountId,
    required String from,
    required String to,
  }) =>
      repository.getSaleMonthSettlements(
          accountId: accountId, from: from, to: to);

  /// This month's payout sums — the dashboard payout card (FEATURE_2610_29 /
  /// D30).
  Future<Either<Failure, SettlementMonthSummary>> getMonthSummary() =>
      repository.getMonthSummary();

  Future<Either<Failure, ReconReport>> getReport(int payoutId) =>
      repository.getReport(payoutId);

  Future<Either<Failure, List<ReconLineView>>> getPayoutLines(int payoutId,
          {String? label, bool? unmatched}) =>
      repository.getPayoutLines(payoutId, label: label, unmatched: unmatched);

  Future<Either<Failure, Uint8List>> exportReport(int payoutId) =>
      repository.exportReport(payoutId);

  Future<Either<Failure, SettlementSyncResult>> syncSettlement(
          {int? accountId, int? sellerId}) =>
      repository.syncSettlement(accountId: accountId, sellerId: sellerId);

  Future<Either<Failure, PayoutSyncResult>> syncPayouts(
          {int? accountId, String? month}) =>
      repository.syncPayouts(accountId: accountId, month: month);

  Future<Either<Failure, SettlementSyncResult>> syncRevenuePeriod({
    required int accountId,
    required String from,
    required String to,
  }) =>
      repository.syncRevenuePeriod(accountId: accountId, from: from, to: to);

  Future<Either<Failure, List<SettlementSyncTarget>>> getSyncTargets(
          {int? sellerId}) =>
      repository.getSyncTargets(sellerId: sellerId);

  Future<Either<Failure, Unit>> markPaid(int payoutId, String paidOn) =>
      repository.markPaid(payoutId, paidOn);

  Future<Either<Failure, Unit>> unmarkPaid(int payoutId) =>
      repository.unmarkPaid(payoutId);

  Future<Either<Failure, List<FirstMonthQuestion>>> getFirstMonthQuestions() =>
      repository.getFirstMonthQuestions();

  Future<Either<Failure, Unit>> answerFirstMonth(int linkId,
          {required bool charged}) =>
      repository.answerFirstMonth(linkId, charged: charged);
}
