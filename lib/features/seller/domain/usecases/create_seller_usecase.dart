import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/seller.dart';
import '../repositories/seller_repository.dart';

class CreateSellerParams {
  final String sellerName;
  final String businessRegistration;

  CreateSellerParams({required this.sellerName, required this.businessRegistration});
}

class CreateSellerUseCase {
  final SellerRepository repository;

  CreateSellerUseCase({required this.repository});

  Future<Either<Failure, Seller>> call(CreateSellerParams params) async =>
      await repository.createSeller(params.sellerName, params.businessRegistration);
}
