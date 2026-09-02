class AppConstants {
  /// Backend API base URL, selected by build environment.
  ///
  /// **Branch → server** (per project convention):
  /// - local dev (`flutter run`) & `develop` builds → DEV server (this default).
  /// - `main` (production release) → existing/original API server, injected at
  ///   build time via `--dart-define=API_BASE_URL=http://100.77.112.35:8083`
  ///   (see `scripts/flutter_env.sh`, which resolves the URL from the git branch).
  ///
  /// The default is intentionally the DEV server so an ad-hoc `flutter run`
  /// never accidentally hits production. Only a `main`/release build overrides it.
  ///
  /// Servers:
  /// - DEV (local + develop): https://api-dev.oclyx.com
  /// - PROD (main only)      : http://100.77.112.35:8083  (existing API server)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-dev.oclyx.com',
  );

  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  /// 쿠팡 OpenAPI를 실시간 재조회하는 무거운 엔드포인트용 per-request 타임아웃(초).
  /// 주문 동기화(POST /api/orders/sync)·Shipping Label 발송처리(POST /confirm)·
  /// preview(GET /v2/preview)는 서버가 쿠팡을 페이징 조회하므로
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
