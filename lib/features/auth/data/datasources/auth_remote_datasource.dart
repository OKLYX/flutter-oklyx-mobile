import 'package:flutter_oklyn_mobile/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Login with email and password
  /// Throws exception on API errors
  /// Throws exception on network errors
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Get current authenticated user
  /// Requires valid authentication token
  /// Throws exception (401 for invalid token) or network exception
  Future<UserModel> getCurrentUser();

  /// Refresh authentication token
  /// Uses refresh token to get new access token
  /// Throws exception or network exception
  Future<UserModel> refreshToken(String refreshToken);
}
