import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/seller.dart';

abstract class SellerRepository {
  Future<Either<Failure, List<Seller>>> getSellers();

  Future<Either<Failure, Seller>> getSellerById(int id);
}
