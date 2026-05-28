import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/commission_rate.dart';
import '../repositories/commission_rate_repository.dart';

class CreateCommissionRateUseCase {
  final CommissionRateRepository _repository;

  CreateCommissionRateUseCase(this._repository);

  Future<Either<Failure, CommissionRate>> call({
    required String platform,
    int? categoryId,
    required double rate,
  }) async {
    return await _repository.createCommissionRate(
      platform: platform,
      categoryId: categoryId,
      rate: rate,
    );
  }
}
