import 'package:equatable/equatable.dart';

class UpdateUserParams extends Equatable {
  final int id;
  final String? name;
  final String? email;
  final String? password;
  final String? role;

  const UpdateUserParams({
    required this.id,
    this.name,
    this.email,
    this.password,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, email, password, role];
}
