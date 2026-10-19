import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/settlement/data/models/settlement_json.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

/// `/api/admin/settlement/**` calls (FEATURE_2610_20 / D18 · D19 — the same
/// calls as the web `SettlementRepositoryImpl`). Every path is ADMIN only.
///
/// - `DioClient` lets every status below 500 through as a normal response —
///   [_ensureOk] turns a non-2xx status into a [ServerException] with the
///   envelope `message` and the status code (403 · 429 are read from it).
/// - An empty filter value is never sent (`from=` would be a 400).
/// - The three `sync*` calls ask the market (Coupang · 11st) → extended receive
///   timeout. They are called from buttons only, never on screen entry (D19).
class SettlementRemoteDataSource {
  final Dio dio;

  SettlementRemoteDataSource({required this.dio});

  static final Options _marketCall = Options(
    receiveTimeout: const Duration(seconds: AppConstants.coupangReceiveTimeout),
  );

  /// GET /api/admin/settlement/payouts — payout-date axis.
  Future<List<PayoutSummary>> getPayouts(
      {int? sellerId, int? accountId, String? from, String? to}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/settlement/payouts',
      queryParameters: <String, dynamic>{
        if (sellerId != null) 'sellerId': sellerId,
        if (accountId != null) 'accountId': accountId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    ));
    return listFromJson(_data(response), payoutSummaryFromJson);
  }

  /// GET /api/admin/settlement/payouts/by-recognition —
  /// revenue-recognition-month axis (sales screen).
  Future<List<PayoutSummary>> getPayoutsByRecognition({
    required String from,
    required String to,
    int? sellerId,
    int? accountId,
  }) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/settlement/payouts/by-recognition',
      queryParameters: <String, dynamic>{
        'from': from,
        'to': to,
        if (sellerId != null) 'sellerId': sellerId,
        if (accountId != null) 'accountId': accountId,
      },
    ));
    return listFromJson(_data(response), payoutSummaryFromJson);
  }

  /// GET /api/admin/settlement/by-sale-month — channel and period are required.
  Future<List<SaleMonthSettlement>> getSaleMonthSettlements({
    required int accountId,
    required String from,
    required String to,
  }) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/settlement/by-sale-month',
      queryParameters: <String, dynamic>{
        'accountId': accountId,
        'from': from,
        'to': to
      },
    ));
    return listFromJson(_data(response), saleMonthSettlementFromJson);
  }

  /// GET /api/admin/settlement/payouts/{id}/report.
  Future<ReconReport> getReport(int payoutId) async {
    final response = _ensureOk(await dio
        .get<dynamic>('/api/admin/settlement/payouts/$payoutId/report'));
    return reconReportFromJson(_object(response));
  }

  /// GET /api/admin/settlement/payouts/{id}/lines — the server filters by
  /// [label] / [unmatched].
  Future<List<ReconLineView>> getPayoutLines(int payoutId,
      {String? label, bool? unmatched}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/settlement/payouts/$payoutId/lines',
      queryParameters: <String, dynamic>{
        if (label != null && label.isNotEmpty) 'label': label,
        if (unmatched != null) 'unmatched': unmatched,
      },
    ));
    return listFromJson(_data(response), reconLineViewFromJson);
  }

  /// GET /api/admin/settlement/payouts/{id}/export — xlsx bytes, no envelope.
  Future<Uint8List> exportReport(int payoutId) async {
    final response = await dio.get<dynamic>(
      '/api/admin/settlement/payouts/$payoutId/export',
      options: Options(responseType: ResponseType.bytes),
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw ServerException('', statusCode: code);
    }
    return Uint8List.fromList(response.data as List<int>);
  }

  /// POST /api/admin/settlement/sync — priority accountId > sellerId > all
  /// (market call).
  Future<SettlementSyncResult> syncSettlement(
      {int? accountId, int? sellerId}) async {
    final response = _ensureOk(await dio.post<dynamic>(
      '/api/admin/settlement/sync',
      queryParameters: <String, dynamic>{
        if (accountId != null)
          'accountId': accountId
        else if (sellerId != null)
          'sellerId': sellerId,
      },
      options: _marketCall,
    ));
    return settlementSyncResultFromJson(_object(response));
  }

  /// POST /api/admin/settlement/payout/sync — [month] `yyyy-MM` = that month
  /// only, anchor untouched.
  Future<PayoutSyncResult> syncPayouts({int? accountId, String? month}) async {
    final response = _ensureOk(await dio.post<dynamic>(
      '/api/admin/settlement/payout/sync',
      queryParameters: <String, dynamic>{
        if (accountId != null) 'accountId': accountId,
        if (month != null && month.isNotEmpty) 'month': month,
      },
      options: _marketCall,
    ));
    return payoutSyncResultFromJson(_object(response));
  }

  /// POST /api/admin/settlement/sync/period — one channel, one month (market
  /// call).
  Future<SettlementSyncResult> syncRevenuePeriod({
    required int accountId,
    required String from,
    required String to,
  }) async {
    final response = _ensureOk(await dio.post<dynamic>(
      '/api/admin/settlement/sync/period',
      queryParameters: <String, dynamic>{
        'accountId': accountId,
        'from': from,
        'to': to
      },
      options: _marketCall,
    ));
    return settlementSyncResultFromJson(_object(response));
  }

  /// GET /api/admin/settlement/sync/targets.
  Future<List<SettlementSyncTarget>> getSyncTargets({int? sellerId}) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/settlement/sync/targets',
      queryParameters: <String, dynamic>{
        if (sellerId != null) 'sellerId': sellerId
      },
    ));
    return listFromJson(_data(response), settlementSyncTargetFromJson);
  }

  /// POST /api/admin/settlement/payouts/{id}/mark-paid — 11st 「지급 완료」 (D34 ·
  /// D38).
  Future<void> markPaid(int payoutId, String paidOn) async {
    _ensureOk(await dio.post<dynamic>(
      '/api/admin/settlement/payouts/$payoutId/mark-paid',
      data: <String, dynamic>{'paidOn': paidOn},
    ));
  }

  /// POST /api/admin/settlement/payouts/{id}/unmark-paid — 11st 「지급 완료 취소」
  /// (D39).
  Future<void> unmarkPaid(int payoutId) async {
    _ensureOk(await dio
        .post<dynamic>('/api/admin/settlement/payouts/$payoutId/unmark-paid'));
  }

  /// GET /api/admin/settlement/first-month-questions (D45 ⑦).
  Future<List<FirstMonthQuestion>> getFirstMonthQuestions() async {
    final response = _ensureOk(
        await dio.get<dynamic>('/api/admin/settlement/first-month-questions'));
    return listFromJson(_data(response), firstMonthQuestionFromJson);
  }

  /// POST /api/admin/settlement/first-month-questions/{linkId} — [예] true ·
  /// [아니오] false (D45 ⑦).
  Future<void> answerFirstMonth(int linkId, {required bool charged}) async {
    _ensureOk(await dio.post<dynamic>(
      '/api/admin/settlement/first-month-questions/$linkId',
      data: <String, dynamic>{'charged': charged},
    ));
  }

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
    throw ServerException(
      '응답 형식이 올바르지 않습니다.',
      statusCode: response.statusCode,
    );
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
