import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/marketplace_account.dart';
import '../repositories/marketplace_account_repository.dart';

class GetMarketplaceAccountsBySellerUseCase {
  final MarketplaceAccountRepository repository;

  GetMarketplaceAccountsBySellerUseCase({required this.repository});

  Future<Either<Failure, List<MarketplaceAccount>>> call(int sellerId) {
    return repository.getBySeller(sellerId);
  }
}
