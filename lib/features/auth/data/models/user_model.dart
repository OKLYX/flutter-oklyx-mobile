import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_oklyn_mobile/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.token,
    super.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convert UserModel to domain User entity
  User toDomain() => User(
    id: id,
    email: email,
    name: name,
    token: token,
    refreshToken: refreshToken,
  );
}
