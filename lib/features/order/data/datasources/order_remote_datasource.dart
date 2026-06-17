import 'package:dio/dio.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  /// GET /api/orders?sellerId={sellerId}
  /// Returns the order list (응답 data 는 OrderItem 배열).
  Future<List<OrderModel>> getOrders({int? sellerId});

  /// POST /api/orders/sync?sellerId={sellerId}
  /// 동기화 후 갱신된 주문 목록 + 건수 요약을 반환한다.
  Future<OrderSyncResultModel> syncOrders({int? sellerId});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio dio;

  OrderRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<OrderModel>> getOrders({int? sellerId}) async {
    try {
      final response = await dio.get(
        '/api/orders',
        queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
      );
      // 백엔드 ResponseDTO 래퍼: response.data = { status, data: [...] }
      // 결과가 없을 때 data: null 로 내려올 수 있어 빈 리스트로 처리한다.
      final data = response.data['data'];
      if (data is! List) return [];
      return data
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch orders');
    }
  }

  @override
  Future<OrderSyncResultModel> syncOrders({int? sellerId}) async {
    try {
      // 프론트와 동일: body 없이 sellerId 를 query param 으로 전송한다.
      final response = await dio.post(
        '/api/orders/sync',
        queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
      );
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        final message = response.data is Map ? response.data['message'] : null;
        throw Exception(message?.toString() ?? 'Failed to sync orders');
      }
      return OrderSyncResultModel.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw Exception(body['message'].toString());
      }
      throw Exception(e.message ?? 'Failed to sync orders');
    }
  }
}
