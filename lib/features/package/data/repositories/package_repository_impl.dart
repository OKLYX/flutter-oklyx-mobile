import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/data/datasources/package_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageRemoteDataSource remoteDataSource;

  PackageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Package>>> getPackages() async {
    try {
      final packages = await remoteDataSource.getPackages();
      return Right(packages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('네트워크 연결을 확인해주세요.'));
    }
  }

  @override
  Future<Either<Failure, Package>> createPackage(CreatePackageParams params) async {
    try {
      final package = await remoteDataSource.createPackage(params);
      return Right(package);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('네트워크 연결을 확인해주세요.'));
    }
  }

  @override
  Future<Either<Failure, Package>> updatePackage({
    required int id,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
  }) async {
    try {
      final package = await remoteDataSource.updatePackage(
        id: id,
        type: type,
        cost: cost,
        effectiveDate: effectiveDate,
        isDefault: isDefault,
      );
      return Right(package);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('네트워크 연결을 확인해주세요.'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePackage(int id) async {
    try {
      await remoteDataSource.deletePackage(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('네트워크 연결을 확인해주세요.'));
    }
  }
}
