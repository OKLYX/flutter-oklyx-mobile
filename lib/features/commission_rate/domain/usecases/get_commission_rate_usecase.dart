import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/commission_rate.dart';
import '../repositories/commission_rate_repository.dart';

class GetCommissionRateUseCase {
  final CommissionRateRepository _repository;

  GetCommissionRateUseCase(this._repository);

  Future<Either<Failure, CommissionRate>> call(int id) async {
    return await _repository.getCommissionRate(id);
  }
}
