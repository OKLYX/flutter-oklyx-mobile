import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/platform_carrier_code.dart';
import '../repositories/carrier_repository.dart';

class CreatePlatformCodeUseCase {
  final CarrierRepository repository;

  CreatePlatformCodeUseCase({required this.repository});

  Future<Either<Failure, PlatformCarrierCode>> call(
    int carrierId,
    String platform,
    String code,
  ) {
    return repository.createPlatformCode(carrierId, platform, code);
  }
}
