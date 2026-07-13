import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier.dart';
import '../repositories/carrier_repository.dart';

class CreateCarrierUseCase {
  final CarrierRepository repository;

  CreateCarrierUseCase({required this.repository});

  Future<Either<Failure, Carrier>> call(String name, bool isActive) {
    return repository.createCarrier(name, isActive);
  }
}
