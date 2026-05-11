import 'package:equatable/equatable.dart';

sealed class UserRegisterEvent extends Equatable {
  const UserRegisterEvent();

  @override
  List<Object?> get props => [];
}

class EmailCheckRequested extends UserRegisterEvent {
  final String email;

  const EmailCheckRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class RegisterUserRequested extends UserRegisterEvent {
  final String email;
  final String password;
  final String name;

  const RegisterUserRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class UserRegisterInitialEvent extends UserRegisterEvent {
  const UserRegisterInitialEvent();

  @override
  List<Object?> get props => [];
}
