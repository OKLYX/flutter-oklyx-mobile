import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'ERROR[${err.type}] => MESSAGE: ${err.message} '
      '=> STATUS CODE: ${err.response?.statusCode}',
    );

    handler.next(err);
  }
}
