import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/packing.dart';
import '../../domain/entities/packing_history.dart';
import '../../domain/repositories/packing_repository.dart';
import '../datasources/packing_remote_datasource.dart';

class PackingRepositoryImpl implements PackingRepository {
  final PackingRemoteDataSource remoteDataSource;

  PackingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PackingScan>> scan(String invoiceNumber) =>
      _guard(() => remoteDataSource.scan(invoiceNumber), '송장 조회에 실패했습니다');

  @override
  Future<Either<Failure, List<PendingParcel>>> pending() =>
      _guard(() => remoteDataSource.pending(), '작업 대상 박스를 불러오지 못했습니다');

  @override
  Future<Either<Failure, BarcodeLookup>> lookupBarcode(
    String value,
    int parcelId,
  ) =>
      _guard(() => remoteDataSource.lookupBarcode(value, parcelId),
          '바코드 조회에 실패했습니다');

  @override
  Future<Either<Failure, List<BoxCandidate>>> boxCandidates(
    List<BoxCandidateItem> items,
  ) =>
      _guard(() => remoteDataSource.boxCandidates(items), '상자 추천을 불러오지 못했습니다');

  @override
  Future<Either<Failure, PackingCompleteResult>> complete(
    int parcelId,
    int boxPackageId,
    List<PackedItem> items,
  ) =>
      _guard(() => remoteDataSource.complete(parcelId, boxPackageId, items),
          '박스 완료에 실패했습니다');

  @override
  Future<Either<Failure, PackingCloseResult>> markUnused(int parcelId) =>
      _guard(() => remoteDataSource.markUnused(parcelId), '박스를 닫지 못했습니다');

  @override
  Future<Either<Failure, PackingCloseResult>> restore(int parcelId) =>
      _guard(() => remoteDataSource.restore(parcelId), '미사용 처리를 되돌리지 못했습니다');

  @override
  Future<Either<Failure, PackingCompleteResult>> changeBox(
    int parcelId,
    int boxPackageId,
  ) =>
      _guard(() => remoteDataSource.changeBox(parcelId, boxPackageId),
          '상자를 바꾸지 못했습니다');

  @override
  Future<Either<Failure, List<PackingHistoryEntry>>> history(
    String from,
    String to,
    String keyword,
  ) =>
      _guard(() => remoteDataSource.history(from, to, keyword),
          '포장 이력을 불러오지 못했습니다');

  /// The server message first — a 400 reason (「이미 출고된 박스입니다」) must
  /// reach the screen as it is.
  Future<Either<Failure, T>> _guard<T>(
      Future<T> Function() call, String fallback) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message.isEmpty ? fallback : e.message,
          statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(fallback, statusCode: e.response?.statusCode));
    } on Exception {
      return Left(ServerFailure(fallback));
    }
  }
}
