import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier.dart';
import '../repositories/carrier_repository.dart';

class GetCarriersUseCase {
  final CarrierRepository repository;

  GetCarriersUseCase({required this.repository});

  Future<Either<Failure, List<Carrier>>> call() {
    return repository.getCarriers();
  }
}
