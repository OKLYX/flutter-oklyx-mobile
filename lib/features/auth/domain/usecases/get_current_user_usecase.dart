import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  /// Get the currently authenticated user
  ///
  /// Retrieves user from local cache or refetches from server if needed
  /// Returns [Either<Failure, User>]
  /// - Right: Current User object
  /// - Left: Failure object (e.g., user not authenticated)
  Future<Either<Failure, User>> call() =>
      repository.getCurrentUser();
}
