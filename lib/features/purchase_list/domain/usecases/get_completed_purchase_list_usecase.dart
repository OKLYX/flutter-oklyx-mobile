import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_list_item.dart';
import '../repositories/purchase_list_repository.dart';

class GetCompletedPurchaseListUseCase {
  final PurchaseListRepository repository;

  GetCompletedPurchaseListUseCase({required this.repository});

  /// 구매일 기간만으로 조회한다 — 판매자 필터는 없다(PLAN 2609_29 D21).
  Future<Either<Failure, List<PurchaseListItem>>> call(
    String? from,
    String? to,
  ) {
    return repository.getCompleted(from, to);
  }
}
