import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/seller.dart';

abstract class SellerRepository {
  Future<Either<Failure, List<Seller>>> getSellers();

  Future<Either<Failure, Seller>> getSellerById(int id);

  Future<Either<Failure, Seller>> createSeller(String sellerName, String businessRegistration);

  Future<Either<Failure, Seller>> updateSeller(int id, String sellerName, String businessRegistration);

  Future<Either<Failure, void>> deleteSeller(int id);
}
