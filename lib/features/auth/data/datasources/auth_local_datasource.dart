abstract class AuthLocalDataSource {
  /// Save authentication token to secure storage
  /// Throws exception on storage errors
  Future<void> saveToken(String token);

  /// Retrieve authentication token from secure storage
  /// Returns null if token not found
  /// Throws exception on storage errors
  Future<String?> getToken();

  /// Delete authentication token from secure storage
  /// Throws exception on storage errors
  Future<void> deleteToken();

  /// Check if authentication token exists in secure storage
  /// Returns false if any error occurs
  Future<bool> hasToken();

  /// Save refresh token to secure storage
  /// Throws exception on storage errors
  Future<void> saveRefreshToken(String refreshToken);

  /// Retrieve refresh token from secure storage
  /// Returns null if refresh token not found
  /// Throws exception on storage errors
  Future<String?> getRefreshToken();

  /// Delete refresh token from secure storage
  /// Throws exception on storage errors
  Future<void> deleteRefreshToken();

  /// Save user data to secure storage
  /// Throws exception on storage errors
  Future<void> saveUser(dynamic user);

  /// Retrieve user data from secure storage
  /// Returns null if user not found
  /// Throws exception on storage errors
  Future<dynamic> getUser();

  /// Delete user data from secure storage
  /// Throws exception on storage errors
  Future<void> deleteUser();
}
