import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier.dart';
import '../entities/platform_carrier_code.dart';

abstract class CarrierRepository {
  Future<Either<Failure, List<Carrier>>> getCarriers();
  Future<Either<Failure, Carrier>> createCarrier(String name, bool isActive);
  Future<Either<Failure, Carrier>> updateCarrier(int id, String name, bool isActive);
  Future<Either<Failure, void>> deleteCarrier(int id);

  Future<Either<Failure, List<PlatformCarrierCode>>> getPlatformCodes(int carrierId);
  Future<Either<Failure, PlatformCarrierCode>> createPlatformCode(
    int carrierId,
    String platform,
    String code,
  );
  Future<Either<Failure, PlatformCarrierCode>> updatePlatformCode(
    int carrierId,
    int codeId,
    String platform,
    String code,
  );
  Future<Either<Failure, void>> deletePlatformCode(int carrierId, int codeId);
}
