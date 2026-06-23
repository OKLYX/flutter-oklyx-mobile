import 'package:dio/dio.dart';
import '../models/add_manual_params.dart';
import '../models/adjust_manual_qty_params.dart';
import '../models/purchase_list_item_model.dart';
import '../models/purchase_list_result_model.dart';
import '../models/record_purchase_params.dart';

abstract class PurchaseListRemoteDataSource {
  Future<PurchaseListResultModel> getList(int? sellerId);
  Future<PurchaseListResultModel> extract(int? sellerId);
  Future<List<PurchaseListItemModel>> getCompleted(
    int? sellerId,
    String? from,
    String? to,
  );
  Future<void> recordPurchase(int itemId, RecordPurchaseParams params);
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
  Future<PurchaseListResultModel> getList(int? sellerId) async {
    final response = await dio.get(
      '/api/admin/purchase-list',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
    );
    return _parseResult(response);
  }

  @override
  Future<PurchaseListResultModel> extract(int? sellerId) async {
    final response = await dio.post(
      '/api/admin/purchase-list/extract',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
    );
    return _parseResult(response);
  }

  /// GET /completed returns { data: [ PurchaseProductGroup ] } (배열, 읽기전용).
  /// 판매자(sellerId) + 구매일 기간(from/to, YYYY-MM-DD)으로 필터링. 빈 값은 생략(=전체).
  @override
  Future<List<PurchaseListItemModel>> getCompleted(
    int? sellerId,
    String? from,
    String? to,
  ) async {
    final params = <String, dynamic>{};
    if (sellerId != null) params['sellerId'] = sellerId;
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

  @override
  Future<void> recordPurchase(int itemId, RecordPurchaseParams params) async {
    await dio.post(
      '/api/admin/purchase-list/items/$itemId/purchases',
      data: params.toJson(),
    );
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
