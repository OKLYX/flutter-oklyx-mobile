import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Execute logout
  ///
  /// Clears user session and removes stored credentials
  /// Returns [Either<Failure, void>]
  /// - Right: void (successful logout)
  /// - Left: Failure object with error details
  Future<Either<Failure, void>> call() =>
      repository.logout();
}
