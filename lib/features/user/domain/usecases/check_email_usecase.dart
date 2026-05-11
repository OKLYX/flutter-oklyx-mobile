import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/repositories/user_repository.dart';

class CheckEmailUseCase {
  final UserRepository repository;

  CheckEmailUseCase(this.repository);

  Future<Either<Failure, bool>> call(String email) =>
      repository.checkEmailExists(email);
}
