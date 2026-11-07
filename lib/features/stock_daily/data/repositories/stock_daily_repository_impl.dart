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
      _guard(() => remoteDataSource.getDaily(date), '일별 입출고 내역을 불러오지 못했습니다.');

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

  @override
  Future<Either<Failure, Unit>> assignWithoutReceipt(
    String movedOn,
    String mode,
    int sellerId,
    List<ReceiptLineParams> lines,
  ) =>
      _guard(() async {
        await remoteDataSource.assignWithoutReceipt(
            movedOn, mode, sellerId, lines);
        return unit;
      }, '판매자를 정하지 못했습니다.');

  @override
  Future<Either<Failure, Unit>> changeSeller(
    int sellerId,
    List<int> movementIds,
    List<int> shareRecordIds,
  ) =>
      _guard(() async {
        await remoteDataSource.changeSeller(
            sellerId, movementIds, shareRecordIds);
        return unit;
      }, '판매자를 바꾸지 못했습니다.');

  @override
  Future<Either<Failure, Unit>> retypePrices(
    String movedOn,
    File? photo,
    int? cardId,
    List<PurchasePriceLine> lines,
  ) =>
      _guard(() async {
        await remoteDataSource.retypePrices(movedOn, photo, cardId, lines);
        return unit;
      }, '매입가를 반영하지 못했습니다.');

  @override
  Future<Either<Failure, Unit>> editRow(
    String movedOn,
    File? photo,
    DailyRowEdit edit,
  ) =>
      _guard(() async {
        await remoteDataSource.editRow(movedOn, photo, edit);
        return unit;
      }, '저장하지 못했습니다.');

  @override
  Future<Either<Failure, List<DayReceipt>>> getDayReceipts(String date) =>
      _guard(
          () => remoteDataSource.getDayReceipts(date), '영수증 목록을 불러오지 못했습니다.');

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
