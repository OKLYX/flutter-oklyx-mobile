import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';

class GetUsersResponse extends Equatable {
  final List<User> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final bool first;
  final bool last;

  const GetUsersResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.first,
    required this.last,
  });

  bool get hasNextPage => !last;
  bool get hasPreviousPage => !first;

  @override
  List<Object?> get props => [
    content,
    totalPages,
    totalElements,
    number,
    first,
    last,
  ];
}
