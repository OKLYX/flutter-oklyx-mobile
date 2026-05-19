import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier_rate.dart';
import '../repositories/carrier_rate_repository.dart';

class GetCarrierRatesUseCase {
  final CarrierRateRepository repository;

  GetCarrierRatesUseCase({required this.repository});

  Future<Either<Failure, List<CarrierRate>>> call() {
    return repository.getCarrierRates();
  }
}
