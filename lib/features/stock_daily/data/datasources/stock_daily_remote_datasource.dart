import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import '../models/stock_daily_model.dart';

/// `GET /api/admin/stock/daily` and `POST /api/admin/purchase-receipts/assign`
/// (FEATURE_2610_19 D119 · D121), `POST
/// /api/admin/purchase-receipts/assign-without-receipt` and `POST
/// /api/admin/stock/daily/change-seller` (FEATURE_2611_01 D2 · D7) — the same
/// calls as the web `StockLotRepositoryImpl`. All are ADMIN only.
///
/// `DioClient` lets every status below 500 through — [_ensureOk] turns a
/// non-2xx status into a [ServerException] with the envelope `message`.
class StockDailyRemoteDataSource {
  final Dio dio;

  StockDailyRemoteDataSource({required this.dio});

  Future<StockDailyModel> getDaily(String date) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/stock/daily',
      queryParameters: <String, dynamic>{'date': date},
    ));
    return StockDailyModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> assign(
    String movedOn,
    File photo,
    CreateReceiptParams params,
  ) async {
    final form = FormData.fromMap({
      // The file name extension sets the part type (jpg → image/jpeg).
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
      // The server reads this part as JSON (@RequestPart).
      'request': MultipartFile.fromString(
        jsonEncode(params.toJson()),
        contentType: DioMediaType('application', 'json'),
      ),
    });
    _ensureOk(await dio.post<dynamic>(
      '/api/admin/purchase-receipts/assign',
      data: form,
      queryParameters: <String, dynamic>{'movedOn': movedOn},
      options: Options(contentType: 'multipart/form-data'),
    ));
  }

  /// [mode] = `RECEIPT_LATER` or `NO_RECEIPT` (FEATURE_2611_01 D4).
  Future<void> assignWithoutReceipt(
    String movedOn,
    String mode,
    int sellerId,
    List<ReceiptLineParams> lines,
  ) async {
    _ensureOk(await dio.post<dynamic>(
      '/api/admin/purchase-receipts/assign-without-receipt',
      data: <String, dynamic>{
        'mode': mode,
        'sellerId': sellerId,
        'lines': lines.map((line) => line.toJson()).toList(),
      },
      queryParameters: <String, dynamic>{'movedOn': movedOn},
    ));
  }

  Future<void> changeSeller(
    int sellerId,
    List<int> movementIds,
    List<int> shareRecordIds,
  ) async {
    _ensureOk(await dio.post<dynamic>(
      '/api/admin/stock/daily/change-seller',
      data: <String, dynamic>{
        'sellerId': sellerId,
        'movementIds': movementIds,
        'shareRecordIds': shareRecordIds,
      },
    ));
  }

  Response<dynamic> _ensureOk(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return response;
    }
    final body = response.data;
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : '';
    throw ServerException(message, statusCode: code);
  }
}
