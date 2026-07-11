class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://100.77.112.35:8083',
  );

  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  /// 쿠팡 OpenAPI를 실시간 재조회하는 무거운 엔드포인트용 per-request 타임아웃(초).
  /// 주문 동기화(POST /api/orders/sync)·Shipping Label 다운로드
  /// (GET /api/admin/shipping-labels/spreadsheet)는 서버가 쿠팡을 페이징 조회하므로
  /// 기본 [receiveTimeout] 30초를 초과할 수 있어 이 값을 개별 요청에만 적용한다.
  static const int coupangReceiveTimeout = 120;

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
