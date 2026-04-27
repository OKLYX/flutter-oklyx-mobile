import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';

import '../entities/user.dart';

abstract class AuthRepository {
  /// Login with email and password
  /// Returns [User] if successful, [Failure] if unsuccessful
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Logout the current user
  /// Returns [void] if successful, [Failure] if unsuccessful
  Future<Either<Failure, void>> logout();

  /// Get the currently authenticated user
  /// Returns [User] if a user is logged in, [Failure] otherwise
  Future<Either<Failure, User>> getCurrentUser();

  /// Refresh the authentication token
  /// Returns new [User] with updated token if successful, [Failure] otherwise
  Future<Either<Failure, User>> refreshToken();

  /// Check if user is currently authenticated
  /// Returns [bool] indicating authentication status
  Future<bool> isAuthenticated();
}
