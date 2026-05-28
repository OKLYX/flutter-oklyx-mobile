import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/commission_rate_repository.dart';

class DeleteCommissionRateUseCase {
  final CommissionRateRepository _repository;

  DeleteCommissionRateUseCase(this._repository);

  Future<Either<Failure, void>> call(int id) async {
    return await _repository.deleteCommissionRate(id);
  }
}
