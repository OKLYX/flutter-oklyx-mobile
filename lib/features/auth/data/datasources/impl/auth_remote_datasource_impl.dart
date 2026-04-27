import 'package:dio/dio.dart';

import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/models/user_model.dart';

import '../auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Login failed',
          statusCode: response.statusCode,
        );
      }

      final jsonData = response.data as Map<String, dynamic>;
      final data = jsonData['data'] as Map<String, dynamic>;

      final userData = {
        'id': data['email'],
        'email': data['email'],
        'name': data['name'],
        'token': data['token'],
        'refreshToken': null,
      };

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.get('/auth/me');

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to get current user',
          statusCode: response.statusCode,
        );
      }

      final jsonData = response.data as Map<String, dynamic>;
      final data = jsonData['data'] as Map<String, dynamic>;

      final userData = {
        'id': data['email'],
        'email': data['email'],
        'name': data['name'],
        'token': data['token'] ?? '',
        'refreshToken': null,
      };

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ServerException(
          AppConstants.unauthorizedMessage,
          statusCode: 401,
        );
      }
      throw ServerException(
        e.message ?? 'Failed to get current user',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Token refresh failed',
          statusCode: response.statusCode,
        );
      }

      final jsonData = response.data as Map<String, dynamic>;
      final data = jsonData['data'] as Map<String, dynamic>;

      final userData = {
        'id': data['email'],
        'email': data['email'],
        'name': data['name'],
        'token': data['token'],
        'refreshToken': null,
      };

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Token refresh failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
