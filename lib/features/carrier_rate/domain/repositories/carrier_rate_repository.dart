import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/carrier_rate.dart';

abstract class CarrierRateRepository {
  Future<Either<Failure, List<CarrierRate>>> getCarrierRates();
}
