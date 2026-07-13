import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/platform_carrier_code.dart';
import '../repositories/carrier_repository.dart';

class UpdatePlatformCodeUseCase {
  final CarrierRepository repository;

  UpdatePlatformCodeUseCase({required this.repository});

  Future<Either<Failure, PlatformCarrierCode>> call(
    int carrierId,
    int codeId,
    String platform,
    String code,
  ) {
    return repository.updatePlatformCode(carrierId, codeId, platform, code);
  }
}
