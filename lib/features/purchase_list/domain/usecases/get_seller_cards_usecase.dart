import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/seller_card.dart';
import '../repositories/purchase_list_repository.dart';

/// Visible cards of every seller — the receipt popup's card list
/// (FEATURE_2610_18 D87 · D91).
class GetSellerCardsUseCase {
  final PurchaseListRepository repository;

  GetSellerCardsUseCase({required this.repository});

  Future<Either<Failure, List<SellerCard>>> call() {
    return repository.getSellerCards();
  }
}
