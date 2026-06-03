import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../repositories/seller_repository.dart';

class UpdateSellerUseCase {
  final SellerRepository repository;

  UpdateSellerUseCase({required this.repository});

  Future<Either<Failure, Seller>> call(
    int id,
    String sellerName,
    String businessRegistration,
  ) {
    return repository.updateSeller(id, sellerName, businessRegistration);
  }
}
