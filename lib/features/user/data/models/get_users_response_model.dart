import 'package:flutter_oklyn_mobile/features/user/data/models/user_model.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_response.dart';

class GetUsersResponseModel extends GetUsersResponse {
  const GetUsersResponseModel({
    required super.content,
    required super.totalPages,
    required super.totalElements,
    required super.number,
    required super.first,
    required super.last,
  });

  factory GetUsersResponseModel.fromJson(Map<String, dynamic> json) {
    return GetUsersResponseModel(
      content: (json['content'] as List<dynamic>)
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
      number: json['number'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content.map((user) {
      if (user is UserModel) {
        return user.toJson();
      }
      return {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': user.updatedAt.toIso8601String(),
      };
    }).toList(),
    'totalPages': totalPages,
    'totalElements': totalElements,
    'number': number,
    'first': first,
    'last': last,
  };
}
