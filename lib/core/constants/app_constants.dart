class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  static const int defaultPageSize = 20;
  static const int defaultPageNumber = 1;

  static const String appVersion = '1.0.0';
  static const String appName = 'Flutter Oklyn Mobile';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';

  static const String networkErrorMessage = 'Network error occurred';
  static const String serverErrorMessage = 'Server error occurred';
  static const String unknownErrorMessage = 'Unknown error occurred';
  static const String unauthorizedMessage = 'Unauthorized access';
}
