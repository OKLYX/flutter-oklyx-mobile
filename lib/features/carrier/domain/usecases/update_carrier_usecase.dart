import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier.dart';
import '../repositories/carrier_repository.dart';

class UpdateCarrierUseCase {
  final CarrierRepository repository;

  UpdateCarrierUseCase({required this.repository});

  Future<Either<Failure, Carrier>> call(int id, String name, bool isActive) {
    return repository.updateCarrier(id, name, isActive);
  }
}
