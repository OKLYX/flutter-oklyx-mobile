import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

sealed class UserManageEvent extends Equatable {
  const UserManageEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersRequested extends UserManageEvent {
  final String? name;
  final String? email;
  final int page;

  const LoadUsersRequested({
    this.name,
    this.email,
    required this.page,
  });

  @override
  List<Object?> get props => [name, email, page];
}

class UserSearchRequested extends UserManageEvent {
  final String name;
  final String email;

  const UserSearchRequested({
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [name, email];
}

class UserPageChanged extends UserManageEvent {
  final int page;

  const UserPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class UserListItemUpdated extends UserManageEvent {
  final User user;

  const UserListItemUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
