import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/seller_repository.dart';

class DeleteSellerUseCase {
  final SellerRepository repository;

  DeleteSellerUseCase({required this.repository});

  Future<Either<Failure, void>> call(int id) {
    return repository.deleteSeller(id);
  }
}
