import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

sealed class UserManageState extends Equatable {
  const UserManageState();

  @override
  List<Object?> get props => [];
}

class UserManageInitial extends UserManageState {
  const UserManageInitial();
}

class UserManageLoading extends UserManageState {
  const UserManageLoading();
}

class UserManageLoaded extends UserManageState {
  final List<User> users;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const UserManageLoaded({
    required this.users,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  @override
  List<Object?> get props => [users, currentPage, totalPages, totalElements];
}

class UserManageError extends UserManageState {
  final String message;

  const UserManageError(this.message);

  @override
  List<Object?> get props => [message];
}
