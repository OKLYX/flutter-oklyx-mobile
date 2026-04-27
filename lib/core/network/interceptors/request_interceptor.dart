import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/auth_local_datasource.dart';

class RequestInterceptor extends QueuedInterceptor {
  final AuthLocalDataSource authLocalDataSource;

  RequestInterceptor({required this.authLocalDataSource});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.addAll({
      'User-Agent': 'flutter-oklyn-mobile/1.0',
      'Content-Type': 'application/json',
    });

    try {
      final hasToken = await authLocalDataSource.hasToken();
      if (hasToken) {
        final token = await authLocalDataSource.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } on Exception {
      // Silently ignore token retrieval errors
      // ErrorInterceptor will handle auth errors (Phase 6.2)
    }

    debugPrint(
      'REQUEST[${options.method}] => PATH: ${options.path} '
      '=> HEADERS: ${options.headers} '
      '=> DATA: ${options.data}',
    );

    handler.next(options);
  }
}
