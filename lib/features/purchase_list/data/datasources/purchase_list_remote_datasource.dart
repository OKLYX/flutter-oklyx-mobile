import 'package:dio/dio.dart';
import '../models/adjust_manual_qty_params.dart';
import '../models/purchase_list_item_model.dart';
import '../models/record_purchase_params.dart';

abstract class PurchaseListRemoteDataSource {
  Future<List<PurchaseListItemModel>> getList(int? sellerId);
  Future<List<PurchaseListItemModel>> extract(int? sellerId);
  Future<void> recordPurchase(int itemId, RecordPurchaseParams params);
  Future<void> adjustManualQty(int itemId, AdjustManualQtyParams params);
}

class PurchaseListRemoteDataSourceImpl implements PurchaseListRemoteDataSource {
  final Dio dio;

  PurchaseListRemoteDataSourceImpl({required this.dio});

  /// Both GET / and POST /extract return { data: { items: [...], unmappedOrders: [...] } }.
  List<PurchaseListItemModel> _parseItems(Response response) {
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? const [];
    return items
        .map((e) => PurchaseListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PurchaseListItemModel>> getList(int? sellerId) async {
    final response = await dio.get(
      '/api/admin/purchase-list',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
    );
    return _parseItems(response);
  }

  @override
  Future<List<PurchaseListItemModel>> extract(int? sellerId) async {
    final response = await dio.post(
      '/api/admin/purchase-list/extract',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
    );
    return _parseItems(response);
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
}
