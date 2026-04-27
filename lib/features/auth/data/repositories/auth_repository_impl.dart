import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/repositories/auth_repository.dart';

import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      await localDataSource.saveToken(userModel.token);
      if (userModel.refreshToken != null) {
        await localDataSource.saveRefreshToken(userModel.refreshToken!);
      }

      return Right(userModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on LocalException catch (e) {
      return Left(LocalFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.deleteToken();
      await localDataSource.deleteRefreshToken();
      return const Right(null);
    } on LocalException catch (e) {
      return Left(LocalFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();

      await localDataSource.saveToken(userModel.token);

      return Right(userModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on LocalException catch (e) {
      return Left(LocalFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final storedRefreshToken = await localDataSource.getRefreshToken();

      if (storedRefreshToken == null) {
        return const Left(
          AuthenticationFailure('No refresh token available'),
        );
      }

      final userModel = await remoteDataSource.refreshToken(storedRefreshToken);

      await localDataSource.saveToken(userModel.token);
      if (userModel.refreshToken != null) {
        await localDataSource.saveRefreshToken(userModel.refreshToken!);
      }

      return Right(userModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on LocalException catch (e) {
      return Left(LocalFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() => localDataSource.hasToken();
}
