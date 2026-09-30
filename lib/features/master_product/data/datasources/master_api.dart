import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';

/// Request helper shared by the three master_product data sources
/// (FEATURE_2609_80 R3).
///
/// - Every request uses [AppConstants.coupangReceiveTimeout] (web axios has no
///   limit — register/import/regenerate can exceed 30 s).
/// - `DioClient` does not throw on 4xx (`validateStatus < 500`), so a non-2xx
///   status throws [ServerException] with the envelope `message` (empty when
///   absent) and the status code.
/// - On 2xx it returns the envelope `data` (`null` when absent).
/// ❌ No user-facing text here — screens add fallbacks via
///    `failureText(failure, '…')`.
class MasterApi {
  final Dio dio;

  MasterApi({required this.dio});

  static final Options _options = Options(
    receiveTimeout: const Duration(seconds: AppConstants.coupangReceiveTimeout),
  );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(dio.get<dynamic>(path, queryParameters: query, options: _options));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(dio.post<dynamic>(path, data: body, options: _options));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(dio.put<dynamic>(path, data: body, options: _options));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(dio.patch<dynamic>(path, data: body, options: _options));

  Future<dynamic> delete(String path) =>
      _send(dio.delete<dynamic>(path, options: _options));

  /// One multipart `file` — Dio sets Content-Type with the boundary (never set
  /// it manually).
  Future<dynamic> postFile(String path, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    return _send(dio.post<dynamic>(path, data: form, options: _options));
  }

  Future<dynamic> _send(Future<Response<dynamic>> request) async {
    final response = await request;
    final code = response.statusCode ?? 0;
    final body = response.data;
    if (code < 200 || code >= 300) {
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : '';
      throw ServerException(message, statusCode: code);
    }
    return body is Map ? body['data'] : null;
  }
}
