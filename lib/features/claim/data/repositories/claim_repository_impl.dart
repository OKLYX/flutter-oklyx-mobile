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
}
