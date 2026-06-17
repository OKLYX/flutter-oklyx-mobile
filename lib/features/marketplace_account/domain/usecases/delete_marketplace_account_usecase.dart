import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/marketplace_account_repository.dart';

class DeleteMarketplaceAccountUseCase {
  final MarketplaceAccountRepository repository;

  DeleteMarketplaceAccountUseCase({required this.repository});

  Future<Either<Failure, void>> call(int id) {
    return repository.delete(id);
  }
}
