import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/repositories/shipping_label_repository.dart';
import '../datasources/shipping_label_remote_datasource.dart';
import '../models/shipment_confirm_result.dart';
import '../models/shipping_label_preview_row.dart';

class ShippingLabelRepositoryImpl implements ShippingLabelRepository {
  final ShippingLabelRemoteDataSource remoteDataSource;

  ShippingLabelRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Uint8List>> downloadSpreadsheet({int? sellerId}) async {
    try {
      final bytes = await remoteDataSource.downloadSpreadsheet(sellerId: sellerId);
      return Right(bytes);
    } on DioException catch (e) {
      // 에러 본문 bytes 는 파싱하지 않고 statusCode 만 전달한다(프론트와 동일).
      return Left(
        ServerFailure(
          e.message ?? 'Failed to download spreadsheet',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShipmentConfirmResult>> confirmShipment({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final result =
          await remoteDataSource.confirmShipment(bytes: bytes, filename: filename);
      return Right(result);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to confirm shipment',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRows({
    int? sellerId,
  }) async {
    try {
      final rows = await remoteDataSource.previewRows(sellerId: sellerId);
      return Right(rows);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to load preview rows',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRowsByOrder({
    required int orderItemId,
  }) async {
    try {
      final rows =
          await remoteDataSource.previewRowsByOrder(orderItemId: orderItemId);
      return Right(rows);
    } on DioException catch (e) {
      // 목록 preview 와 동일하게 에러 본문은 파싱하지 않고 statusCode 만 전달한다.
      return Left(
        ServerFailure(
          e.message ?? 'Failed to load order sheet',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportSpreadsheet(
    List<ShippingLabelPreviewRow> rows,
  ) async {
    try {
      final bytes = await remoteDataSource.exportSpreadsheet(rows);
      return Right(bytes);
    } on DioException catch (e) {
      // export 는 bytes 응답이라 에러 본문도 bytes → 상태코드만 전달(본문 미파싱).
      return Left(
        ServerFailure(
          e.message ?? 'Failed to export spreadsheet',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
