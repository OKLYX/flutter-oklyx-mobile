import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/marketplace_account.dart';
import '../repositories/marketplace_account_repository.dart';

class CreateMarketplaceAccountUseCase {
  final MarketplaceAccountRepository repository;

  CreateMarketplaceAccountUseCase({required this.repository});

  Future<Either<Failure, MarketplaceAccount>> call(CreateMarketplaceAccountParams params) {
    return repository.create(params);
  }
}
