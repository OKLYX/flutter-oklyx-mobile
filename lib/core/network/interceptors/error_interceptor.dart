import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_oklyn_mobile/features/auth/domain/repositories/auth_repository.dart';

class ErrorInterceptor extends QueuedInterceptor {
  final Dio dio;
  final AuthRepository authRepository;
  final VoidCallback onLogoutRequired;

  bool _isRefreshingToken = false;
  late Completer<void> _refreshTokenCompleter;

  ErrorInterceptor({
    required this.dio,
    required this.authRepository,
    required this.onLogoutRequired,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint(
      'ERROR[${err.type}] => MESSAGE: ${err.message} '
      '=> STATUS CODE: ${err.response?.statusCode}',
    );

    if (err.response?.statusCode == 401) {
      if (_isRefreshingToken) {
        // Wait for ongoing refresh
        await _refreshTokenCompleter.future;
        // Retry request
        try {
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } on Exception {
          handler.next(err);
          return;
        }
      }

      _isRefreshingToken = true;
      _refreshTokenCompleter = Completer<void>();

      try {
        final result = await authRepository.refreshToken();
        result.fold(
          (failure) {
            // Refresh failed
            onLogoutRequired();
            _isRefreshingToken = false;
            _refreshTokenCompleter.complete();
            handler.next(err);
          },
          (user) {
            // Refresh successful
            _updateAndRetryRequest(err, user, handler);
          },
        );
      } on Exception {
        onLogoutRequired();
        _isRefreshingToken = false;
        _refreshTokenCompleter.complete();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _updateAndRetryRequest(
    DioException err,
    dynamic user,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      await authRepository.cacheUser(user);
      err.requestOptions.headers['Authorization'] = 'Bearer ${user.token}';
      _isRefreshingToken = false;
      _refreshTokenCompleter.complete();

      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on Exception {
      handler.next(err);
    }
  }
}
