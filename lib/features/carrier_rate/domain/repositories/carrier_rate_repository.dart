import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier_rate.dart';

abstract class CarrierRateRepository {
  Future<Either<Failure, List<CarrierRate>>> getCarrierRates();
  Future<Either<Failure, CarrierRate>> getCarrierRate(int id);
  Future<Either<Failure, CarrierRate>> createCarrierRate(
    String carrier,
    String type,
    double cost,
    String effectiveDate,
    bool isDefault,
  );
  Future<Either<Failure, CarrierRate>> updateCarrierRate(
    int id,
    String carrier,
    String type,
    double cost,
    String effectiveDate,
    bool isDefault,
  );
  Future<Either<Failure, void>> deleteCarrierRate(int id);
}
