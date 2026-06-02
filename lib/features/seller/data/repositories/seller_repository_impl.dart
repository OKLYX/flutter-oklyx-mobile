import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/seller.dart';
import '../../domain/repositories/seller_repository.dart';
import '../datasources/seller_remote_datasource.dart';

class SellerRepositoryImpl implements SellerRepository {
  final SellerRemoteDataSource remoteDataSource;

  SellerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Seller>>> getSellers() async {
    try {
      final sellers = await remoteDataSource.getSellers();
      return Right(sellers);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to fetch sellers'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Seller>> getSellerById(int id) async {
    try {
      final seller = await remoteDataSource.getSellerById(id);
      return Right(seller);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to fetch seller'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
