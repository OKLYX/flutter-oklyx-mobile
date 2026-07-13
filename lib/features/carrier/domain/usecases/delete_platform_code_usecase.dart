import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/carrier_repository.dart';

class DeletePlatformCodeUseCase {
  final CarrierRepository repository;

  DeletePlatformCodeUseCase({required this.repository});

  Future<Either<Failure, void>> call(int carrierId, int codeId) {
    return repository.deletePlatformCode(carrierId, codeId);
  }
}
