import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier_rate.dart';
import '../repositories/carrier_rate_repository.dart';

class UpdateCarrierRateParams {
  final int id;
  final int carrierId;
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;

  UpdateCarrierRateParams({
    required this.id,
    required this.carrierId,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });
}

class UpdateCarrierRateUseCase {
  final CarrierRateRepository repository;

  UpdateCarrierRateUseCase({required this.repository});

  Future<Either<Failure, CarrierRate>> call(UpdateCarrierRateParams params) {
    return repository.updateCarrierRate(
      params.id,
      params.carrierId,
      params.type,
      params.cost,
      params.effectiveDate,
      params.isDefault,
    );
  }
}
