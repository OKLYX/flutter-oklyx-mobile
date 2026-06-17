import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/marketplace_account.dart';
import '../../domain/repositories/marketplace_account_repository.dart';
import '../datasources/marketplace_account_remote_datasource.dart';

class MarketplaceAccountRepositoryImpl implements MarketplaceAccountRepository {
  final MarketplaceAccountRemoteDataSource remoteDataSource;

  MarketplaceAccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MarketplaceAccount>>> getBySeller(int sellerId) async {
    try {
      final channels = await remoteDataSource.getBySeller(sellerId);
      return Right(channels);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      return Left(ServerFailure(_extractErrorMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MarketplaceAccount>> create(
      CreateMarketplaceAccountParams params) async {
    try {
      final channel = await remoteDataSource.create(params);
      return Right(channel);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      return Left(ServerFailure(_extractErrorMessage(e)));
    } catch (e) {
      final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : e.toString();
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, MarketplaceAccount>> update(
      int id, UpdateMarketplaceAccountParams params) async {
    try {
      final channel = await remoteDataSource.update(id, params);
      return Right(channel);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      return Left(ServerFailure(_extractErrorMessage(e)));
    } catch (e) {
      final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : e.toString();
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await remoteDataSource.delete(id);
      return const Right(null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('서버 연결 실패'));
      }
      return Left(ServerFailure(_extractErrorMessage(e)));
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
    return e.message ?? '판매채널 요청에 실패했습니다';
  }
}
