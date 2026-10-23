import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';

/// 「매출」 lookups (FEATURE_2610_20 / D26) — local DB reads only, no market call.
/// A failure carries the HTTP status in `ServerFailure.statusCode` (403 = not
/// admin — D20).
abstract class SalesRepository {
  Future<Either<Failure, List<SellerSales>>> getSellerSummary(
      {required String from, required String to});

  Future<Either<Failure, List<ChannelSales>>> getChannelSales(
      {required String from, required String to, int? sellerId});

  Future<Either<Failure, List<SalesLine>>> getSalesLines(
      {required String from, required String to, required int accountId});

  Future<Either<Failure, List<DailySales>>> getDailySales(
      {required String from, required String to, int? sellerId});

  Future<Either<Failure, List<ProductProfit>>> getProductProfit({
    required String from,
    required String to,
    required bool crossChannel,
    int? sellerId,
  });

  Future<Either<Failure, SavingsSummary>> getSavingsSummary(
      {required String from, required String to});

  Future<Either<Failure, List<OptionSaving>>> getOptionSavings(
      {required String from, required String to, int? sellerId});

  Future<Either<Failure, List<BoxSaving>>> getBoxSavings(
      {required String from, required String to});
}
