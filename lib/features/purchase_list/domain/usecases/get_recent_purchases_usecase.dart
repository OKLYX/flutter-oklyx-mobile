import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_record.dart';
import '../repositories/purchase_list_repository.dart';

/// 물품 기준 최근 구매이력 지연 조회 (PLAN 2609_29 D9).
///
/// ⚠️ 판매자 조건이 없다 — 그 물품을 누가 샀든 최신순으로 섞여 나온다.
/// 목록 응답에 싣지 않고, 입고 카드가 [최근 구매이력]을 펼칠 때만 부른다.
/// 구매목록 탭과 완료 탭이 **같은 usecase 를 재사용**한다(D21).
class GetRecentPurchasesUseCase {
  final PurchaseListRepository repository;

  GetRecentPurchasesUseCase({required this.repository});

  Future<Either<Failure, List<PurchaseRecord>>> call(
    int productId, {
    int limit = 5,
  }) {
    return repository.recentPurchases(productId, limit: limit);
  }
}
