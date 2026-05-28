import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/commission_rate.dart';

abstract class CommissionRateRepository {
  Future<Either<Failure, List<CommissionRate>>> getCommissionRates();
  Future<Either<Failure, CommissionRate>> getCommissionRate(int id);
  Future<Either<Failure, CommissionRate>> createCommissionRate({
    required String platform,
    int? categoryId,
    required double rate,
  });
  Future<Either<Failure, CommissionRate>> updateCommissionRate({
    required int id,
    String? platform,
    int? categoryId,
    double? rate,
  });
  Future<Either<Failure, void>> deleteCommissionRate(int id);
}
