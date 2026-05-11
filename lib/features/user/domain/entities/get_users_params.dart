import 'package:equatable/equatable.dart';

class GetUsersParams extends Equatable {
  final String? name;
  final String? email;
  final int page;
  final int size;

  const GetUsersParams({
    this.name,
    this.email,
    required this.page,
    this.size = 20,
  });

  @override
  List<Object?> get props => [name, email, page, size];
}
