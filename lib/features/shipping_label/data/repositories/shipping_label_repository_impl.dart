import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/repositories/shipping_label_repository.dart';
import '../datasources/shipping_label_remote_datasource.dart';
import '../models/carrier_option.dart';
import '../models/manual_shipment_result.dart';
import '../models/shipment_confirm_result.dart';
import '../models/shipping_label_preview_row.dart';

class ShippingLabelRepositoryImpl implements ShippingLabelRepository {
  final ShippingLabelRemoteDataSource remoteDataSource;

  ShippingLabelRepositoryImpl({required this.remoteDataSource});

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

  @override
  Future<Either<Failure, List<CarrierOption>>> getCarrierOptions({
    required String platform,
  }) async {
    try {
      final options =
          await remoteDataSource.getCarrierOptions(platform: platform);
      return Right(options);
    } on DioException catch (e) {
      // 화면은 statusCode 로만 분기한다(403 = 섹션 숨김) — 본문 미파싱.
      return Left(
        ServerFailure(
          e.message ?? 'Failed to load carrier options',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ManualShipmentResult>> confirmManualShipment({
    required int orderItemId,
    required int carrierId,
    required String invoiceNumber,
  }) async {
    try {
      final result = await remoteDataSource.confirmManualShipment(
        orderItemId: orderItemId,
        carrierId: carrierId,
        invoiceNumber: invoiceNumber,
      );
      return Right(result);
    } on DioException catch (e) {
      // ⚠️ 이 경로만 다른 메서드와 다르다 — 400 사유가 여러 개라(비-쿠팡 주문 / 박스 ID 없음 /
      // 택배사 코드 미등록) 서버 본문 message 를 그대로 살려 화면에 노출한다(PLAN 2609_11).
      // 실패 봉투 {status:'FAILURE', message, data:null}.
      final body = e.response?.data;
      final serverMessage =
          body is Map<String, dynamic> ? body['message'] as String? : null;
      return Left(
        ServerFailure(
          serverMessage ?? e.message ?? 'Failed to confirm manual shipment',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
