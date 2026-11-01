import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/repositories/stock_daily_repository.dart';
import '../datasources/stock_daily_remote_datasource.dart';

class StockDailyRepositoryImpl implements StockDailyRepository {
  final StockDailyRemoteDataSource remoteDataSource;

  StockDailyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, StockDaily>> getDaily(String date) =>
      _guard(() => remoteDataSource.getDaily(date), '그날 입출고 내역을 불러오지 못했습니다.');

  @override
  Future<Either<Failure, Unit>> assign(
    String movedOn,
    File photo,
    CreateReceiptParams params,
  ) =>
      _guard(() async {
        await remoteDataSource.assign(movedOn, photo, params);
        return unit;
      }, '영수증을 배정하지 못했습니다.');

  /// The server message first — a 400 reason (「남은 영수증 미등록 수량…」)
  /// must reach the screen as it is.
  Future<Either<Failure, T>> _guard<T>(
      Future<T> Function() call, String fallback) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message.isEmpty ? fallback : e.message,
          statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? fallback,
          statusCode: e.response?.statusCode));
    } on Exception {
      return Left(ServerFailure(fallback));
    }
  }
}
