import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

sealed class UserEditState extends Equatable {
  const UserEditState();

  @override
  List<Object?> get props => [];
}

class UserEditInitial extends UserEditState {
  const UserEditInitial();
}

class UserEditLoaded extends UserEditState {
  final User user;

  const UserEditLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class EmailChecking extends UserEditState {
  const EmailChecking();
}

class EmailAvailable extends UserEditState {
  const EmailAvailable();
}

class EmailDuplicate extends UserEditState {
  final String message;

  const EmailDuplicate(this.message);

  @override
  List<Object?> get props => [message];
}

class UserUpdating extends UserEditState {
  const UserUpdating();
}

class UserUpdateSuccess extends UserEditState {
  final User user;

  const UserUpdateSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class UserEditError extends UserEditState {
  final String message;

  const UserEditError(this.message);

  @override
  List<Object?> get props => [message];
}
