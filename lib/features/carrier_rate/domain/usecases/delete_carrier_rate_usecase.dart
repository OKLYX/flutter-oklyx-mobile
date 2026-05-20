import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/repositories/carrier_rate_repository.dart';

class DeleteCarrierRateUseCase {
  final CarrierRateRepository repository;

  DeleteCarrierRateUseCase({required this.repository});

  Future<Either<Failure, void>> call(int id) {
    return repository.deleteCarrierRate(id);
  }
}
