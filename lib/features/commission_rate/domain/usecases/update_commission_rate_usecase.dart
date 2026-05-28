import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/commission_rate.dart';
import '../repositories/commission_rate_repository.dart';

class UpdateCommissionRateUseCase {
  final CommissionRateRepository _repository;

  UpdateCommissionRateUseCase(this._repository);

  Future<Either<Failure, CommissionRate>> call({
    required int id,
    String? platform,
    int? categoryId,
    double? rate,
  }) async {
    return await _repository.updateCommissionRate(
      id: id,
      platform: platform,
      categoryId: categoryId,
      rate: rate,
    );
  }
}
