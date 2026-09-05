import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/claim.dart';

abstract class ClaimRepository {
  /// 클레임 목록 조회
  /// GET /api/claims?type={type}&sellerId=&status=&keyword=&from=&to=
  ///
  /// [type] 은 Stage A 에서 항상 [ClaimType.returnClaim] 이다(교환은 08).
  /// [from]/[to] 는 'YYYY-MM-DD'. **둘 다 주거나 둘 다 생략**한다 —
  /// 하나만 주면 서버가 400 을 낸다. 둘 다 생략하면 서버 기본 창(최근 2주).
  Future<Either<Failure, List<Claim>>> getClaims({
    required ClaimType type,
    int? sellerId,
    ClaimStatus? status,
    String? keyword,
    String? from,
    String? to,
  });

  /// 클레임 단건 조회
  /// GET /api/claims/{id}
  ///
  /// ⚠️ 목록 화면의 상세 진입은 이 API 를 쓰지 않는다(`extra` 전달, 주문 상세와 동일).
  /// 딥링크 등 후속에서 필요할 때를 위한 계약이다.
  Future<Either<Failure, Claim>> getClaim(int id);
}
