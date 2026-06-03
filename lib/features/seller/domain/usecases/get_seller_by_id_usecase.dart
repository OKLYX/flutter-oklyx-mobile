import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/seller.dart';
import '../repositories/seller_repository.dart';

class GetSellerByIdUseCase {
  final SellerRepository repository;

  GetSellerByIdUseCase({required this.repository});

  Future<Either<Failure, Seller>> call(int id) async {
    return await repository.getSellerById(id);
  }
}
