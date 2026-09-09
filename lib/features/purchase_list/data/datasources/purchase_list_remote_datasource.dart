import 'package:dio/dio.dart';
import '../models/add_manual_params.dart';
import '../models/adjust_manual_qty_params.dart';
import '../models/purchase_list_item_model.dart';
import '../models/purchase_list_result_model.dart';
import '../models/purchase_record_model.dart';
import '../models/purchase_record_result_model.dart';
import '../models/record_purchase_params.dart';

/// 구매목록 API (PLAN 2609_29).
///
/// 🔴 조회·추출에 sellerId 쿼리 파라미터가 없다(D11) — 항상 전체다.
/// 판매자는 입고 요청 본문의 귀속 값으로만 등장한다.
abstract class PurchaseListRemoteDataSource {
  Future<PurchaseListResultModel> getList();
  Future<PurchaseListResultModel> extract();
  Future<List<PurchaseListItemModel>> getCompleted(String? from, String? to);
  Future<PurchaseRecordResultModel> recordPurchase(RecordPurchaseParams params);
  Future<List<PurchaseRecordModel>> recentPurchases(int productId, int limit);
  Future<void> adjustManualQty(int itemId, AdjustManualQtyParams params);
  Future<void> addManual(AddManualParams params);
}

class PurchaseListRemoteDataSourceImpl implements PurchaseListRemoteDataSource {
  final Dio dio;

  PurchaseListRemoteDataSourceImpl({required this.dio});

  /// Both GET / and POST /extract return { data: { items: [...], unmappedOrders: [...] } }.
  PurchaseListResultModel _parseResult(Response response) {
    final data = response.data['data'] as Map<String, dynamic>;
    return PurchaseListResultModel.fromJson(data);
  }

  @override
  Future<PurchaseListResultModel> getList() async {
    final response = await dio.get('/api/admin/purchase-list');
    return _parseResult(response);
  }

  @override
  Future<PurchaseListResultModel> extract() async {
    final response = await dio.post('/api/admin/purchase-list/extract');
    return _parseResult(response);
  }

  /// GET /completed returns { data: [ PurchaseProductGroup ] } (배열).
  /// 구매일 기간(from/to, YYYY-MM-DD)으로만 필터링한다 — 판매자 필터는 없다(D21).
  @override
  Future<List<PurchaseListItemModel>> getCompleted(
    String? from,
    String? to,
  ) async {
    final params = <String, dynamic>{};
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;
    final response = await dio.get(
      '/api/admin/purchase-list/completed',
      queryParameters: params.isEmpty ? null : params,
    );
    final items = (response.data['data'] as List<dynamic>?) ?? const [];
    return items
        .map((e) => PurchaseListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 입고 1회 — 물품 × 판매자. 응답 { data: { purchaseRecordId, stockRecorded } }.
  @override
  Future<PurchaseRecordResultModel> recordPurchase(
    RecordPurchaseParams params,
  ) async {
    final response = await dio.post(
      '/api/admin/purchase-list/purchases',
      data: params.toJson(),
    );
    return PurchaseRecordResultModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// 그 물품의 최근 구매이력 — **판매자 조건이 없다**(D9). 최신순 [limit]건.
  @override
  Future<List<PurchaseRecordModel>> recentPurchases(
    int productId,
    int limit,
  ) async {
    final response = await dio.get(
      '/api/admin/purchase-list/purchases',
      queryParameters: {'productId': productId, 'limit': limit},
    );
    final records = (response.data['data'] as List<dynamic>?) ?? const [];
    return records
        .map((e) => PurchaseRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> adjustManualQty(int itemId, AdjustManualQtyParams params) async {
    await dio.patch(
      '/api/admin/purchase-list/items/$itemId',
      data: params.toJson(),
    );
  }

  @override
  Future<void> addManual(AddManualParams params) async {
    await dio.post(
      '/api/admin/purchase-list/manual',
      data: params.toJson(),
    );
  }
}
