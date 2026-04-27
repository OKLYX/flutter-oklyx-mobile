import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import './params/login_params.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Execute login with email and password
  ///
  /// [params] contains email and password
  /// Returns [Either<Failure, User>]
  /// - Right: User object with auth token
  /// - Left: Failure object with error details
  Future<Either<Failure, User>> call(LoginParams params) =>
      repository.login(
        email: params.email,
        password: params.password,
      );
}
