import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/carrier_repository.dart';

class DeleteCarrierUseCase {
  final CarrierRepository repository;

  DeleteCarrierUseCase({required this.repository});

  Future<Either<Failure, void>> call(int id) {
    return repository.deleteCarrier(id);
  }
}
