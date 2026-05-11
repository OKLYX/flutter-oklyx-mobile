import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

sealed class UserRegisterState extends Equatable {
  const UserRegisterState();

  @override
  List<Object?> get props => [];
}

class UserRegisterInitial extends UserRegisterState {
  const UserRegisterInitial();
}

class EmailChecking extends UserRegisterState {
  const EmailChecking();
}

class EmailAvailable extends UserRegisterState {
  const EmailAvailable();
}

class EmailDuplicate extends UserRegisterState {
  final String message;

  const EmailDuplicate(this.message);

  @override
  List<Object?> get props => [message];
}

class UserRegistering extends UserRegisterState {
  const UserRegistering();
}

class UserRegisterSuccess extends UserRegisterState {
  final User user;

  const UserRegisterSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class UserRegisterError extends UserRegisterState {
  final String message;

  const UserRegisterError(this.message);

  @override
  List<Object?> get props => [message];
}
