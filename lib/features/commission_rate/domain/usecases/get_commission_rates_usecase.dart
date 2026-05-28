import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/commission_rate.dart';
import '../repositories/commission_rate_repository.dart';

class GetCommissionRatesUseCase {
  final CommissionRateRepository _repository;

  GetCommissionRatesUseCase(this._repository);

  Future<Either<Failure, List<CommissionRate>>> call() async {
    return await _repository.getCommissionRates();
  }
}
