import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/seller.dart';
import '../repositories/seller_repository.dart';

class GetSellersUseCase {
  final SellerRepository repository;

  GetSellersUseCase({required this.repository});

  Future<Either<Failure, List<Seller>>> call() {
    return repository.getSellers();
  }
}
