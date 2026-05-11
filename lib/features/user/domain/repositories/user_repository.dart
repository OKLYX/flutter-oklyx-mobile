import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_params.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_response.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/update_user_params.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, bool>> checkEmailExists(String email);
  Future<Either<Failure, User>> createUser(String email, String password, String name);
  Future<Either<Failure, GetUsersResponse>> getUsers(GetUsersParams params);
  Future<Either<Failure, User>> updateUser(UpdateUserParams params);
}
