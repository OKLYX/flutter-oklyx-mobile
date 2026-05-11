import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

sealed class UserEditEvent extends Equatable {
  const UserEditEvent();

  @override
  List<Object?> get props => [];
}

class UserEditInitialized extends UserEditEvent {
  final User user;

  const UserEditInitialized(this.user);

  @override
  List<Object?> get props => [user];
}

class EmailCheckRequested extends UserEditEvent {
  final String email;
  final String originalEmail;

  const EmailCheckRequested({
    required this.email,
    required this.originalEmail,
  });

  @override
  List<Object?> get props => [email, originalEmail];
}

class UserUpdateRequested extends UserEditEvent {
  final int id;
  final String? name;
  final String? email;
  final String? password;
  final String? role;

  const UserUpdateRequested({
    required this.id,
    this.name,
    this.email,
    this.password,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, email, password, role];
}
