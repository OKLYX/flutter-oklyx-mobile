import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/platform_carrier_code.dart';
import '../repositories/carrier_repository.dart';

class GetPlatformCodesUseCase {
  final CarrierRepository repository;

  GetPlatformCodesUseCase({required this.repository});

  Future<Either<Failure, List<PlatformCarrierCode>>> call(int carrierId) {
    return repository.getPlatformCodes(carrierId);
  }
}
