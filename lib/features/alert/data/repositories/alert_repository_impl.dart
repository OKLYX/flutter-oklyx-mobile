import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/alert_summary.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/alert_remote_datasource.dart';

/// 알림 배지 Repository 구현 — 예외를 [Failure] 로 바꾸는 유일한 자리.
class AlertRepositoryImpl implements AlertRepository {
  final AlertRemoteDataSource remoteDataSource;

  AlertRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AlertSummary>> getSummary() async {
    try {
      final summary = await remoteDataSource.getSummary();
      return Right(summary);
    } on DioException catch (e) {
      final body = e.response?.data;
      final envelope = body is Map ? body : const {};
      final serverMessage = envelope['message'];
      final message = (serverMessage is String && serverMessage.isNotEmpty)
          ? serverMessage
          : (e.message ?? '알림 건수를 불러오지 못했습니다.');
      return Left(ServerFailure(message, statusCode: e.response?.statusCode));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
