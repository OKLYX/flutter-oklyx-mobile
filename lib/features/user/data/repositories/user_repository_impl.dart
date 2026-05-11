import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    try {
      final exists = await remoteDataSource.checkEmailExists(email);
      return Right(exists);
    } on DuplicateEmailException catch (e) {
      return Left(DuplicateEmailFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to check email: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> createUser(
    String email,
    String password,
    String name,
  ) async {
    try {
      final user = await remoteDataSource.createUser(email, password, name);
      return Right(user);
    } on DuplicateEmailException catch (e) {
      return Left(DuplicateEmailFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to create user: $e'));
    }
  }
}
