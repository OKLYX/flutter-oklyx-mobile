import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/repositories/sales_repository.dart';

/// 「매출」 use case (FEATURE_2610_20 / D26) — a thin pass-through, the web
/// `SalesStatsUseCase` + `PackingSavingsUseCase`.
class SalesUseCase {
  final SalesRepository repository;

  SalesUseCase({required this.repository});

  Future<Either<Failure, List<SellerSales>>> getSellerSummary(
          {required String from, required String to}) =>
      repository.getSellerSummary(from: from, to: to);

  Future<Either<Failure, List<ChannelSales>>> getChannelSales(
          {required String from, required String to, int? sellerId}) =>
      repository.getChannelSales(from: from, to: to, sellerId: sellerId);

  Future<Either<Failure, List<SalesLine>>> getSalesLines(
          {required String from, required String to, required int accountId}) =>
      repository.getSalesLines(from: from, to: to, accountId: accountId);

  Future<Either<Failure, List<ProductProfit>>> getProductProfit({
    required String from,
    required String to,
    required bool crossChannel,
    int? sellerId,
  }) =>
      repository.getProductProfit(
          from: from, to: to, crossChannel: crossChannel, sellerId: sellerId);

  Future<Either<Failure, SavingsSummary>> getSavingsSummary(
          {required String from, required String to}) =>
      repository.getSavingsSummary(from: from, to: to);

  Future<Either<Failure, List<OptionSaving>>> getOptionSavings(
          {required String from, required String to, int? sellerId}) =>
      repository.getOptionSavings(from: from, to: to, sellerId: sellerId);

  Future<Either<Failure, List<BoxSaving>>> getBoxSavings(
          {required String from, required String to}) =>
      repository.getBoxSavings(from: from, to: to);
}
