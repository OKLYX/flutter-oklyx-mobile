import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/repositories/shipping_label_repository.dart';
import '../datasources/shipping_label_remote_datasource.dart';

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
}
