import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/alert_feed_item.dart';
import '../../domain/entities/alert_summary.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/alert_remote_datasource.dart';

/// 알림 Repository 구현 — 예외를 [Failure] 로 바꾸는 유일한 자리.
class AlertRepositoryImpl implements AlertRepository {
  final AlertRemoteDataSource remoteDataSource;

  AlertRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AlertSummary>> getSummary() async {
    try {
      final summary = await remoteDataSource.getSummary();
      return Right(summary);
    } on DioException catch (e) {
      return Left(_toFailure(e, '알림 건수를 불러오지 못했습니다.'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AlertFeedPage>> getFeed({
    AlertType? type,
    String? cursor,
    int size = 50,
  }) async {
    try {
      final page = await remoteDataSource.getFeed(
        type: type,
        cursor: cursor,
        size: size,
      );
      return Right(page);
    } on DioException catch (e) {
      return Left(_toFailure(e, '처리해야 할 일을 불러오지 못했습니다.'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 서버 문구가 있으면 그대로 쓴다 — 앱이 사유를 지어내지 않는다.
  ServerFailure _toFailure(DioException e, String fallback) {
    final body = e.response?.data;
    final envelope = body is Map ? body : const {};
    final serverMessage = envelope['message'];
    final message = (serverMessage is String && serverMessage.isNotEmpty)
        ? serverMessage
        : (e.message ?? fallback);
    return ServerFailure(message, statusCode: e.response?.statusCode);
  }
}
