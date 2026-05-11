import 'package:dio/dio.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/user/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<bool> checkEmailExists(String email);
  Future<UserModel> createUser(String email, String password, String name);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient dioClient;

  UserRemoteDataSourceImpl(this.dioClient);

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await dioClient.get(
        '/api/users/check-email',
        queryParameters: {'email': email},
      );
      return response.data['data']['exists'] as bool;
    } catch (e) {
      throw ServerException('Failed to check email: $e');
    }
  }

  @override
  Future<UserModel> createUser(String email, String password, String name) async {
    try {
      final response = await dioClient.post(
        '/api/users',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw DuplicateEmailException('이미 사용 중인 이메일입니다');
      }
      throw ServerException(
        e.message ?? 'Server error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('Failed to create user: $e');
    }
  }
}
