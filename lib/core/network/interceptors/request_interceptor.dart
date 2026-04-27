import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'User-Agent': 'flutter-oklyn-mobile/1.0',
      'Content-Type': 'application/json',
    });

    debugPrint(
      'REQUEST[${options.method}] => PATH: ${options.path} '
      '=> HEADERS: ${options.headers} '
      '=> DATA: ${options.data}',
    );

    handler.next(options);
  }
}
