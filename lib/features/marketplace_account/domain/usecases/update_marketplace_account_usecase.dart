import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/marketplace_account.dart';
import '../repositories/marketplace_account_repository.dart';

class UpdateMarketplaceAccountParamsWithId {
  final int id;
  final UpdateMarketplaceAccountParams params;

  const UpdateMarketplaceAccountParamsWithId({required this.id, required this.params});
}

class UpdateMarketplaceAccountUseCase {
  final MarketplaceAccountRepository repository;

  UpdateMarketplaceAccountUseCase({required this.repository});

  Future<Either<Failure, MarketplaceAccount>> call(UpdateMarketplaceAccountParamsWithId params) {
    return repository.update(params.id, params.params);
  }
}
