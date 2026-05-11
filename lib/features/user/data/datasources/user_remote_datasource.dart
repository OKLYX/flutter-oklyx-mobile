import 'package:dio/dio.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/user/data/models/get_users_response_model.dart';
import 'package:flutter_oklyn_mobile/features/user/data/models/user_model.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_params.dart';

abstract class UserRemoteDataSource {
  Future<bool> checkEmailExists(String email);
  Future<UserModel> createUser(String email, String password, String name);
  Future<GetUsersResponseModel> getUsers(GetUsersParams params);
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

  @override
  Future<GetUsersResponseModel> getUsers(GetUsersParams params) async {
    try {
      final queryParams = {
        'page': params.page.toString(),
        'size': params.size.toString(),
      };

      // Single search param: name takes priority over email per API limitation
      if (params.name != null && params.name!.isNotEmpty) {
        queryParams['search'] = params.name!;
      } else if (params.email != null && params.email!.isNotEmpty) {
        queryParams['search'] = params.email!;
      }

      final response = await dioClient.get(
        '/api/users',
        queryParameters: queryParams,
      );
      return GetUsersResponseModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ServerException('Failed to get users: $e');
    }
  }
}
