import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode;
    final path = response.requestOptions.path;
    final data = response.data;
    debugPrint(
      'RESPONSE[$statusCode] => PATH: $path => DATA: $data',
    );

    handler.next(response);
  }
}
