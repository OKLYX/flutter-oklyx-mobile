import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../datasources/claim_remote_datasource.dart';

class ClaimRepositoryImpl implements ClaimRepository {
  final ClaimRemoteDataSource remoteDataSource;

  ClaimRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Claim>>> getClaims({
    required ClaimType type,
    int? sellerId,
    ClaimStatus? status,
    String? keyword,
    String? from,
    String? to,
  }) async {
    try {
      // enum → 와이어 값 변환은 여기 한 곳뿐이다(화면·BLoC 은 enum 만 다룬다).
      final claims = await remoteDataSource.getClaims(
        type: type.wire,
        sellerId: sellerId,
        status: status?.wire,
        keyword: keyword,
        from: from,
        to: to,
      );
      return Right(claims.cast<Claim>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch claims',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Claim>> getClaim(int id) async {
    try {
      final claim = await remoteDataSource.getClaim(id);
      return Right(claim);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch claim',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClaimActionResult>> executeAction(
    int claimId,
    ClaimActionRequest request,
  ) async {
    try {
      // null 필드는 toJson 이 제거한다 — 빈 문자열을 보내면 서버의 requires 검증이 통과한다.
      final result = await remoteDataSource.executeAction(claimId, request.toJson());
      return Right(result);
    } on DioException catch (e) {
      return Left(_toActionFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 액션 실패 응답 → [ClaimActionFailure].
  ///
  /// 🔴 조회 경로처럼 `ServerFailure(e.message)` 로 뭉개면 안 된다 — 409(이미 처리된 접수)를
  /// 400 과 구분하지 못하고, 502 에서 보여줄 쿠팡 원문(`data.resultCode`/`data.resultMessage`)이
  /// 사라진다. 웹(03)이 읽는 경로와 같은 자리를 읽는다.
  ClaimActionFailure _toActionFailure(DioException e) {
    final body = e.response?.data;
    final envelope = body is Map ? body : const {};
    final payload = envelope['data'];
    final raw = payload is Map ? payload : const {};
    return ClaimActionFailure(
      envelope['message'] as String? ?? e.message ?? '처리에 실패했습니다.',
      statusCode: e.response?.statusCode,
      resultCode: raw['resultCode'] as String?,
      resultMessage: raw['resultMessage'] as String?,
    );
  }
}
