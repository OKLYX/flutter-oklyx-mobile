import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/models/user_model.dart';

import '../auth_local_datasource.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveToken(String token) async {
    try {
      await secureStorage.write(
        key: AppConstants.tokenKey,
        value: token,
      );
    } catch (e) {
      throw LocalException('Failed to save token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final token = await secureStorage.read(key: AppConstants.tokenKey);
      if (token == null) {
        throw LocalException('Token not found');
      }
      return token;
    } on Exception catch (e) {
      throw LocalException('Failed to retrieve token: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await secureStorage.delete(key: AppConstants.tokenKey);
    } catch (e) {
      throw LocalException('Failed to delete token: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasToken() async {
    try {
      final token = await secureStorage.read(key: AppConstants.tokenKey);
      return token != null;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      );
    } catch (e) {
      throw LocalException('Failed to save refresh token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await secureStorage.read(key: AppConstants.refreshTokenKey);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> deleteRefreshToken() async {
    try {
      await secureStorage.delete(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw LocalException('Failed to delete refresh token: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUser(dynamic user) async {
    try {
      final userModel = user is UserModel ? user : user as UserModel;
      final jsonString = jsonEncode(userModel.toJson());
      await secureStorage.write(
        key: AppConstants.userKey,
        value: jsonString,
      );
    } catch (e) {
      throw LocalException('Failed to save user: ${e.toString()}');
    }
  }

  @override
  Future<dynamic> getUser() async {
    try {
      final jsonString = await secureStorage.read(key: AppConstants.userKey);
      if (jsonString == null) {
        return null;
      }
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(json).toDomain();
    } catch (e) {
      throw LocalException('Failed to retrieve user: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await secureStorage.delete(key: AppConstants.userKey);
    } catch (e) {
      throw LocalException('Failed to delete user: ${e.toString()}');
    }
  }
}
