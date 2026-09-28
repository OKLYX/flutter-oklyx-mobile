import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/purchase_place.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

/// 구매처 목록 조회 (FEATURE_2609_76) — `GET /api/admin/purchase-places`, 모든 로그인 사용자.
class GetPurchasePlacesUseCase {
  final ProductRepository repository;

  GetPurchasePlacesUseCase(this.repository);

  Future<Either<Failure, List<PurchasePlace>>> call() =>
      repository.getPurchasePlaces();
}
