import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Handles an expired access token: on a 401 response it refreshes the token
/// once and re-sends the original request once.
///
/// - 401 arrives in `onResponse`, not `onError`: `DioClient` sets
///   `validateStatus` to accept every status below 500.
/// - Concurrent 401s share one refresh `Future<bool>`.
/// - `onLogoutRequired` fires only when the session is over: no stored
///   refresh token, or `/api/auth/refresh` answered 401.
///
/// ⚠️ Must stay a plain `Interceptor`. A queued interceptor that re-sends on
/// the same Dio waits behind itself and never completes.
/// ❌ Do not handle 401 in `onError` — it never arrives there.
class ErrorInterceptor extends Interceptor {
  final Dio dio;
  final AuthRepository authRepository;
  final VoidCallback onLogoutRequired;

  static const Set<String> _authExemptPaths = {
    '/api/auth/login',
    '/api/auth/refresh',
    '/api/auth/logout',
  };
  static const String _retriedKey = 'authRetried';

  Future<bool>? _refreshing;
  String _accessToken = '';

  ErrorInterceptor({
    required this.dio,
    required this.authRepository,
    required this.onLogoutRequired,
  });

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (response.statusCode != 401 ||
        _authExemptPaths.contains(options.path) ||
        options.extra[_retriedKey] == true) {
      handler.next(response);
      return;
    }

    final refreshed = await (_refreshing ??= _refresh());
    if (!refreshed) {
      handler.next(response);
      return;
    }

    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer $_accessToken';
    try {
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'ERROR[${err.type}] => MESSAGE: ${err.message} '
      '=> STATUS CODE: ${err.response?.statusCode}',
    );
    handler.next(err);
  }

  Future<bool> _refresh() async {
    try {
      final result = await authRepository.refreshToken();
      return result.fold<bool>(
        (failure) {
          if (_isSessionExpired(failure)) {
            onLogoutRequired();
          }
          return false;
        },
        (user) {
          _accessToken = user.token;
          return true;
        },
      );
    } finally {
      _refreshing = null;
    }
  }

  bool _isSessionExpired(Failure failure) =>
      failure is AuthenticationFailure ||
      (failure is ServerFailure && failure.statusCode == 401);
}
