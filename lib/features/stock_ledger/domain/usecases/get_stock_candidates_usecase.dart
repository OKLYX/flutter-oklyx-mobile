import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/purchase_candidate.dart';
import '../entities/return_candidate.dart';
import '../repositories/stock_ledger_repository.dart';

/// 입고 선택지 조회 — 매입 입고의 구매기록, 반품입고의 반품 건.
///
/// 두 목록을 한 usecase 에 둔다: 쓰는 화면이 입고·조정 하나뿐이고 호출 시점도 같아서
/// 파일만 늘어난다. 서버 엔드포인트는 각각 `purchase-candidates`·`return-candidates` 다.
class GetStockCandidatesUseCase {
  final StockLedgerRepository repository;

  GetStockCandidatesUseCase({required this.repository});

  /// 입고 대기 구매기록. [productId] 로 좁힐 수 있다.
  Future<Either<Failure, List<PurchaseCandidate>>> purchases({int? productId}) {
    return repository.purchaseCandidates(productId: productId);
  }

  /// 반품 입고 대기 클레임 (필터 없음).
  Future<Either<Failure, List<ReturnCandidate>>> returns() {
    return repository.returnCandidates();
  }
}
