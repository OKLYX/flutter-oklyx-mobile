import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/repositories/user_repository.dart';

class CreateUserParams extends Equatable {
  final String email;
  final String password;
  final String name;

  const CreateUserParams({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<Either<Failure, User>> call(CreateUserParams params) =>
      repository.createUser(params.email, params.password, params.name);
}
