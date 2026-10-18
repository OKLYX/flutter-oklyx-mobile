import 'package:dio/dio.dart';
import '../models/add_manual_params.dart';
import '../models/adjust_manual_qty_params.dart';
import '../models/purchase_list_item_model.dart';
import '../models/purchase_list_result_model.dart';
import '../models/purchase_record_model.dart';
import '../models/purchase_record_result_model.dart';
import '../models/record_purchase_params.dart';

/// Purchase list API (PLAN 2609_29 · FEATURE_2610_09).
///
/// 🔴 `sellerId` is a view filter on the reads only — the extract takes none and
/// always reloads every seller (FEATURE_2610_09 D4 · D19).
abstract class PurchaseListRemoteDataSource {
  Future<PurchaseListResultModel> getList(int? sellerId);
  Future<PurchaseListResultModel> extract();
  Future<List<PurchaseListItemModel>> getCompleted(
    String? from,
    String? to,
    int? sellerId,
  );
  Future<PurchaseRecordResultModel> recordPurchase(RecordPurchaseParams params);
  Future<List<PurchaseRecordModel>> recentPurchases(
    int productId,
    int limit,
    int? sellerId,
  );
  Future<void> adjustManualQty(int itemId, AdjustManualQtyParams params);
  Future<void> addManual(AddManualParams params);
  Future<void> changeManualSeller(int itemId, int sellerId);
  Future<void> deleteManual(int itemId);
  Future<void> check(int productId, int sellerId, String status);
  Future<void> cancelCheck(int checkId);

  /// `GET /api/admin/purchase-settings` → `stockLinked` (any signed-in user).
  Future<bool> getStockLinked();
}

class PurchaseListRemoteDataSourceImpl implements PurchaseListRemoteDataSource {
  final Dio dio;

  PurchaseListRemoteDataSourceImpl({required this.dio});

  /// GET / and POST /extract return
  /// { data: { items: [...], skippedToday: [...], unmappedOrders: [...] } }.
  PurchaseListResultModel _parseResult(Response response) {
    final data = response.data['data'] as Map<String, dynamic>;
    return PurchaseListResultModel.fromJson(data);
  }

  @override
  Future<PurchaseListResultModel> getList(int? sellerId) async {
    final response = await dio.get(
      '/api/admin/purchase-list',
      queryParameters: sellerId == null ? null : {'sellerId': sellerId},
    );
    return _parseResult(response);
  }

  @override
  Future<PurchaseListResultModel> extract() async {
    final response = await dio.post('/api/admin/purchase-list/extract');
    return _parseResult(response);
  }

  /// GET /completed returns { data: [ PurchaseProductGroup ] }.
  /// Processing-day range (from/to, YYYY-MM-DD) + optional seller
  /// (FEATURE_2610_09 D5 · D63).
  @override
  Future<List<PurchaseListItemModel>> getCompleted(
    String? from,
    String? to,
    int? sellerId,
  ) async {
    final params = <String, dynamic>{};
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;
    if (sellerId != null) params['sellerId'] = sellerId;
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

  /// Recent purchases of a product, newest first, [limit] rows; [sellerId]
  /// null = every seller (FEATURE_2610_09 D7 · D25).
  @override
  Future<List<PurchaseRecordModel>> recentPurchases(
    int productId,
    int limit,
    int? sellerId,
  ) async {
    final response = await dio.get(
      '/api/admin/purchase-list/purchases',
      queryParameters: {
        'productId': productId,
        'limit': limit,
        if (sellerId != null) 'sellerId': sellerId,
      },
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

  @override
  Future<void> changeManualSeller(int itemId, int sellerId) async {
    await dio.patch(
      '/api/admin/purchase-list/items/$itemId/seller',
      data: {'sellerId': sellerId},
    );
  }

  @override
  Future<void> deleteManual(int itemId) async {
    await dio.delete('/api/admin/purchase-list/items/$itemId');
  }

  @override
  Future<void> check(int productId, int sellerId, String status) async {
    await dio.post(
      '/api/admin/purchase-list/checks',
      data: {'productId': productId, 'sellerId': sellerId, 'status': status},
    );
  }

  @override
  Future<void> cancelCheck(int checkId) async {
    await dio.post('/api/admin/purchase-list/checks/$checkId/cancel');
  }

  @override
  Future<bool> getStockLinked() async {
    final response = await dio.get('/api/admin/purchase-settings');
    final data = response.data['data'] as Map<String, dynamic>;
    return data['stockLinked'] as bool;
  }
}
