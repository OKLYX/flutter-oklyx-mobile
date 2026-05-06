import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/exceptions/stock_exceptions.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRemoteDatasource remoteDatasource;

  StockRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, GetStockResponse>> getCurrentStock(String barcodeId) async {
    try {
      final response = await remoteDatasource.getCurrentStock(barcodeId);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on StockInsufficientException {
      return Left(ServerFailure('재고가 부족합니다'));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CreateStockResponse>> createStock(
    CreateStockRequest data,
  ) async {
    try {
      final response = await remoteDatasource.createStock(data);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on StockInsufficientException {
      return Left(ServerFailure('재고가 부족합니다'));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
