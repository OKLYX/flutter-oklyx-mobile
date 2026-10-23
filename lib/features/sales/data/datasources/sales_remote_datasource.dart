import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/sales/data/models/sales_json.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';

/// `/api/admin/sales/**` and `/api/admin/packing/savings/**` lookups
/// (FEATURE_2610_20 / D26 — the same calls as the web
/// `SalesStatsRepositoryImpl` · `PackingSavingsRepositoryImpl`). Every path is
/// ADMIN only.
///
/// - `DioClient` lets every status below 500 through — [_ensureOk] turns a
///   non-2xx status into a [ServerException] with the envelope `message` and
///   the status code (403 is read from it).
/// - An empty filter value is never sent.
class SalesRemoteDataSource {
  final Dio dio;

  SalesRemoteDataSource({required this.dio});

  /// GET /api/admin/sales/summary — one row per seller.
  Future<List<SellerSales>> getSellerSummary(
      {required String from, required String to}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/sales/summary',
      queryParameters: _query(from: from, to: to),
    ));
    return listFromJson(_data(response), sellerSalesFromJson);
  }

  /// GET /api/admin/sales/by-channel — one row per channel ([sellerId] narrows
  /// to one seller).
  Future<List<ChannelSales>> getChannelSales(
      {required String from, required String to, int? sellerId}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/sales/by-channel',
      queryParameters: _query(from: from, to: to, sellerId: sellerId),
    ));
    return listFromJson(_data(response), channelSalesFromJson);
  }

  /// GET /api/admin/sales/lines — the order lines of one channel.
  Future<List<SalesLine>> getSalesLines(
      {required String from,
      required String to,
      required int accountId}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/sales/lines',
      queryParameters: <String, dynamic>{
        'accountId': accountId,
        ..._query(from: from, to: to)
      },
    ));
    return listFromJson(_data(response), salesLineFromJson);
  }

  /// GET /api/admin/sales/daily — one row per sale date (FEATURE_2610_29 /
  /// D22).
  Future<List<DailySales>> getDailySales(
      {required String from, required String to}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/sales/daily',
      queryParameters: _query(from: from, to: to),
    ));
    return listFromJson(_data(response), dailySalesFromJson);
  }

  /// GET /api/admin/sales/by-product — [crossChannel] true = one row per
  /// master, false = per master × channel.
  Future<List<ProductProfit>> getProductProfit({
    required String from,
    required String to,
    required bool crossChannel,
    int? sellerId,
  }) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/sales/by-product',
      queryParameters: <String, dynamic>{
        ..._query(from: from, to: to, sellerId: sellerId),
        'crossChannel': crossChannel,
      },
    ));
    return listFromJson(_data(response), productProfitFromJson);
  }

  /// GET /api/admin/packing/savings/summary — packing-date axis.
  Future<SavingsSummary> getSavingsSummary(
      {required String from, required String to}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/packing/savings/summary',
      queryParameters: _query(from: from, to: to),
    ));
    return savingsSummaryFromJson(_object(response));
  }

  /// GET /api/admin/packing/savings/options — one row per master option.
  Future<List<OptionSaving>> getOptionSavings(
      {required String from, required String to, int? sellerId}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/packing/savings/options',
      queryParameters: _query(from: from, to: to, sellerId: sellerId),
    ));
    return listFromJson(_data(response), optionSavingFromJson);
  }

  /// GET /api/admin/packing/savings/boxes — one row per box, highest total
  /// first.
  Future<List<BoxSaving>> getBoxSavings(
      {required String from, required String to}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/packing/savings/boxes',
      queryParameters: _query(from: from, to: to),
    ));
    return listFromJson(_data(response), boxSavingFromJson);
  }

  static Map<String, dynamic> _query(
          {required String from, required String to, int? sellerId}) =>
      <String, dynamic>{
        if (from.isNotEmpty) 'from': from,
        if (to.isNotEmpty) 'to': to,
        if (sellerId != null) 'sellerId': sellerId,
      };

  static Object? _data(Response<dynamic> response) {
    final body = response.data;
    return body is Map ? body['data'] : null;
  }

  /// The envelope `data` as an object; anything else is a broken answer.
  static Json _object(Response<dynamic> response) {
    final data = _data(response);
    if (data is Json) {
      return data;
    }
    throw ServerException('응답 형식이 올바르지 않습니다.', statusCode: response.statusCode);
  }

  /// A non-2xx status → [ServerException] with the envelope `message` (empty
  /// when absent) and the status code.
  static Response<dynamic> _ensureOk(Response<dynamic> response) {
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
