import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier_rate.dart';
import '../repositories/carrier_rate_repository.dart';

class GetCarrierRateUseCase {
  final CarrierRateRepository repository;

  GetCarrierRateUseCase({required this.repository});

  Future<Either<Failure, CarrierRate>> call(int id) {
    return repository.getCarrierRate(id);
  }
}
