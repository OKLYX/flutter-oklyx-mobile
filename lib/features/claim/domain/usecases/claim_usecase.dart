import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

/// 클레임 조회 UseCase (OrderUseCase 와 동일하게 Repository 에 위임).
class ClaimUseCase {
  final ClaimRepository repository;

  ClaimUseCase({required this.repository});

  /// [from]/[to] 는 'YYYY-MM-DD'. 둘 다 주거나 둘 다 생략(서버 기본 창).
  Future<Either<Failure, List<Claim>>> getClaims({
    required ClaimType type,
    int? sellerId,
    ClaimStatus? status,
    String? keyword,
    String? from,
    String? to,
  }) {
    return repository.getClaims(
      type: type,
      sellerId: sellerId,
      status: status,
      keyword: keyword,
      from: from,
      to: to,
    );
  }

  Future<Either<Failure, Claim>> getClaim(int id) => repository.getClaim(id);

  /// 처리 액션 실행 (ADMIN 전용 — 모바일엔 role 게이트가 없어 서버 403 이 유일한 방어선, D13).
  Future<Either<Failure, ClaimActionResult>> executeAction(
    int claimId,
    ClaimActionRequest request,
  ) =>
      repository.executeAction(claimId, request);
}
