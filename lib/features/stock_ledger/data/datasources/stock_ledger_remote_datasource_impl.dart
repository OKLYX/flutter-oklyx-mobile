import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import '../../domain/entities/stock_intake.dart';
import '../../domain/entities/stock_work.dart';
import '../models/claim_work_model.dart';
import '../models/intake_barcode_result_model.dart';
import '../models/outbound_order_model.dart';
import '../models/purchase_candidate_model.dart';
import '../models/return_candidate_model.dart';
import '../models/stock_balance_model.dart';
import '../models/stock_movement_model.dart';
import '../models/confirm_outbound_params.dart';
import '../models/record_movement_params.dart';
import 'stock_ledger_remote_datasource.dart';

/// 모든 응답은 `{ data: ... }` 봉투다 (ResponseDTO).
class StockLedgerRemoteDataSourceImpl implements StockLedgerRemoteDataSource {
  final Dio dio;

  StockLedgerRemoteDataSourceImpl({required this.dio});

  static const String _base = '/api/admin/stock';

  List<dynamic> _list(Response response) =>
      (response.data['data'] as List<dynamic>?) ?? const [];

  /// 빈 문자열·null 파라미터는 실어 보내지 않는다 — `keyword=` 는 "%%" 필터로 오해된다.
  Map<String, dynamic>? _query(Map<String, dynamic> raw) {
    final params = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      params[key] = value is String ? value.trim() : value;
    });
    return params.isEmpty ? null : params;
  }

  @override
  Future<List<StockBalanceModel>> balances(
    int? productId,
    int? sellerId,
    String? keyword,
  ) async {
    final response = await dio.get(
      '$_base/balances',
      queryParameters: _query({
        'productId': productId,
        'sellerId': sellerId,
        'keyword': keyword,
      }),
    );
    return _list(response)
        .map((e) => StockBalanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StockMovementModel>> movements(
    int? productId,
    int? sellerId,
    String? from,
    String? to,
  ) async {
    final response = await dio.get(
      '$_base/movements',
      queryParameters: _query({
        'productId': productId,
        'sellerId': sellerId,
        'from': from,
        'to': to,
      }),
    );
    return _list(response)
        .map((e) => StockMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StockMovementModel> record(RecordMovementParams params) async {
    final response = await dio.post('$_base/movements', data: params.toJson());
    return StockMovementModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<PurchaseCandidateModel>> purchaseCandidates(int? productId) async {
    final response = await dio.get(
      '$_base/purchase-candidates',
      queryParameters: _query({'productId': productId}),
    );
    return _list(response)
        .map((e) => PurchaseCandidateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReturnCandidateModel>> returnCandidates() async {
    final response = await dio.get('$_base/return-candidates');
    return _list(response)
        .map((e) => ReturnCandidateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OutboundResultModel> outbound(int? sellerId, String? status) async {
    final response = await dio.get(
      '$_base/outbound',
      queryParameters: _query({'sellerId': sellerId, 'status': status}),
    );
    return OutboundResultModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<StockMovementModel>> confirmOutbound(
    ConfirmOutboundParams params,
  ) async {
    final response = await dio.post(
      '$_base/outbound/confirm',
      data: params.toJson(),
    );
    return _list(response)
        .map((e) => StockMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<IntakeBarcodeResultModel> intakeBarcode(String value) async {
    final response = _ensureOk(await dio.get(
      '$_base/intake/barcode',
      queryParameters: {'value': value},
    ));
    return IntakeBarcodeResultModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<int>> intake(
    String movedOn,
    List<StockIntakeLine> lines,
  ) async {
    final response = _ensureOk(await dio.post(
      '$_base/intake',
      data: {
        'movedOn': movedOn,
        'lines': [
          for (final line in lines)
            {
              'productId': line.productId,
              'quantity': line.quantity,
              if (line.sellerId != null) 'sellerId': line.sellerId,
              'reason': line.reason.code,
            },
        ],
      },
    ));
    final data = response.data['data'];
    final lotIds = data is Map ? data['lotIds'] as List<dynamic>? : null;
    return (lotIds ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
  }

  @override
  Future<void> outboundWork(
    String movedOn,
    List<OutboundWorkLineRequest> lines,
  ) async {
    _ensureOk(await dio.post(
      '$_base/outbound-work',
      data: {
        'movedOn': movedOn,
        'lines': [
          for (final line in lines)
            {
              'productId': line.productId,
              'sellerId': line.sellerId,
              'reason': line.reason.code,
              if (line.reasonNote != null) 'reasonNote': line.reasonNote,
              'quantity': line.quantity,
            },
        ],
      },
    ));
  }

  @override
  Future<List<ClaimWorkModel>> claimsByReturnInvoice(String value) =>
      _claims('$_base/return-work/by-return-invoice', {'value': value});

  @override
  Future<List<ClaimWorkModel>> claimsByParcelInvoice(String value) =>
      _claims('$_base/return-work/by-parcel-invoice', {'value': value});

  @override
  Future<List<ShippedOrderModel>> shippedOrders() async {
    final response = _ensureOk(
      await dio.get('$_base/return-work/shipped-orders'),
    );
    return _list(response)
        .map((e) => ShippedOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ClaimWorkModel>> claimsByOrder(int orderId) =>
      _claims('$_base/return-work/orders/$orderId', null);

  @override
  Future<void> returnWork(
    String movedOn,
    List<ClaimWorkLineRequest> lines,
  ) async {
    _ensureOk(await dio.post(
      '$_base/return-work',
      data: _claimWorkBody(movedOn, lines),
    ));
  }

  @override
  Future<List<ClaimWorkModel>> claimsByReshipInvoice(String value) =>
      _claims('$_base/exchange-work/by-reship-invoice', {'value': value});

  @override
  Future<List<ClaimWorkModel>> openExchanges() =>
      _claims('$_base/exchange-work/open', null);

  @override
  Future<void> exchangeWork(
    String movedOn,
    List<ClaimWorkLineRequest> lines,
  ) async {
    _ensureOk(await dio.post(
      '$_base/exchange-work',
      data: _claimWorkBody(movedOn, lines),
    ));
  }

  /// One claim work lookup (FEATURE_2611_34 D35 ① ② ③ ⑥).
  Future<List<ClaimWorkModel>> _claims(
    String path,
    Map<String, dynamic>? query,
  ) async {
    final response = _ensureOk(await dio.get(path, queryParameters: query));
    return _list(response)
        .map((e) => ClaimWorkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Body of the 「반품 재입고」 / 「교환 발송」 save (PLAN §3-3).
  Map<String, dynamic> _claimWorkBody(
    String movedOn,
    List<ClaimWorkLineRequest> lines,
  ) =>
      {
        'movedOn': movedOn,
        'lines': [
          for (final line in lines)
            {
              'orderClaimId': line.orderClaimId,
              'productId': line.productId,
              'quantity': line.quantity,
            },
        ],
      };

  /// Outside 2xx throws [ServerException] with the server message (empty
  /// when the body has none) — FEATURE_2611_33 · 2611_34 calls only.
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
