import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier_rate.dart';
import '../repositories/carrier_rate_repository.dart';

class CreateCarrierRateParams {
  final int carrierId;
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;

  CreateCarrierRateParams({
    required this.carrierId,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });
}

class CreateCarrierRateUseCase {
  final CarrierRateRepository repository;

  CreateCarrierRateUseCase({required this.repository});

  Future<Either<Failure, CarrierRate>> call(CreateCarrierRateParams params) {
    return repository.createCarrierRate(
      params.carrierId,
      params.type,
      params.cost,
      params.effectiveDate,
      params.isDefault,
    );
  }
}
