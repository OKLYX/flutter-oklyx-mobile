import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/update_user_params.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/repositories/user_repository.dart';

class UpdateUserUseCase {
  final UserRepository userRepository;

  UpdateUserUseCase(this.userRepository);

  Future<Either<Failure, User>> call(UpdateUserParams params) async {
    return userRepository.updateUser(params);
  }
}
