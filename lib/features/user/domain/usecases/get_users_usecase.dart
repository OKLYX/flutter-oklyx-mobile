import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_params.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_response.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<Either<Failure, GetUsersResponse>> call(GetUsersParams params) =>
      repository.getUsers(params);
}
