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

  @override
  Future<Either<Failure, Seller>> createSeller(String sellerName, String businessRegistration) async {
    try {
      final seller = await remoteDataSource.createSeller(sellerName, businessRegistration);
      return Right(seller);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      // 서버 응답의 message 필드 추출
      final errorMessage = _extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : e.toString();
      return Left(ServerFailure(message));
    }
  }

  String _extractErrorMessage(DioException e) {
    try {
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    } catch (_) {
      // Fallback to default message
    }
    return e.message ?? 'Failed to create seller';
  }
}
