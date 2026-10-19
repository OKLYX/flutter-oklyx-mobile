import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/settlement/data/datasources/settlement_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/repositories/settlement_repository.dart';

/// [SettlementRepository] implementation — the only place exceptions become
/// [Failure]s (FEATURE_2610_20).
///
/// 🔴 The status code travels in `ServerFailure.statusCode` — the screens tell
/// 403 (「관리자만 볼 수 있습니다.」, D20) and 429 (rate limit, D24) apart by it alone.
class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementRemoteDataSource remoteDataSource;

  SettlementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PayoutSummary>>> getPayouts({
    int? sellerId,
    int? accountId,
    String? from,
    String? to,
  }) =>
      _guard(() => remoteDataSource.getPayouts(
          sellerId: sellerId, accountId: accountId, from: from, to: to));

  @override
  Future<Either<Failure, List<PayoutSummary>>> getPayoutsByRecognition({
    required String from,
    required String to,
    int? sellerId,
  }) =>
      _guard(() => remoteDataSource.getPayoutsByRecognition(
          from: from, to: to, sellerId: sellerId));

  @override
  Future<Either<Failure, List<SaleMonthSettlement>>> getSaleMonthSettlements({
    required int accountId,
    required String from,
    required String to,
  }) =>
      _guard(() => remoteDataSource.getSaleMonthSettlements(
          accountId: accountId, from: from, to: to));

  @override
  Future<Either<Failure, ReconReport>> getReport(int payoutId) =>
      _guard(() => remoteDataSource.getReport(payoutId));

  @override
  Future<Either<Failure, List<ReconLineView>>> getPayoutLines(int payoutId,
          {String? label, bool? unmatched}) =>
      _guard(() => remoteDataSource.getPayoutLines(payoutId,
          label: label, unmatched: unmatched));

  @override
  Future<Either<Failure, Uint8List>> exportReport(int payoutId) =>
      _guard(() => remoteDataSource.exportReport(payoutId));

  @override
  Future<Either<Failure, SettlementSyncResult>> syncSettlement(
          {int? accountId, int? sellerId}) =>
      _guard(() => remoteDataSource.syncSettlement(
          accountId: accountId, sellerId: sellerId));

  @override
  Future<Either<Failure, PayoutSyncResult>> syncPayouts(
          {int? accountId, String? month}) =>
      _guard(() =>
          remoteDataSource.syncPayouts(accountId: accountId, month: month));

  @override
  Future<Either<Failure, SettlementSyncResult>> syncRevenuePeriod({
    required int accountId,
    required String from,
    required String to,
  }) =>
      _guard(() => remoteDataSource.syncRevenuePeriod(
          accountId: accountId, from: from, to: to));

  @override
  Future<Either<Failure, List<SettlementSyncTarget>>> getSyncTargets(
          {int? sellerId}) =>
      _guard(() => remoteDataSource.getSyncTargets(sellerId: sellerId));

  @override
  Future<Either<Failure, Unit>> markPaid(int payoutId, String paidOn) =>
      _guard(() async {
        await remoteDataSource.markPaid(payoutId, paidOn);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> unmarkPaid(int payoutId) => _guard(() async {
        await remoteDataSource.unmarkPaid(payoutId);
        return unit;
      });

  @override
  Future<Either<Failure, List<FirstMonthQuestion>>> getFirstMonthQuestions() =>
      _guard(remoteDataSource.getFirstMonthQuestions);

  @override
  Future<Either<Failure, Unit>> answerFirstMonth(int linkId,
          {required bool charged}) =>
      _guard(() async {
        await remoteDataSource.answerFirstMonth(linkId, charged: charged);
        return unit;
      });

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? ''));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
