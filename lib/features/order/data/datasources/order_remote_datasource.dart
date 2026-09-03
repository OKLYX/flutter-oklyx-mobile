import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/sync_target_model.dart';

abstract class OrderRemoteDataSource {
  /// GET /api/orders?sellerId={sellerId}&from={from}&to={to}
  /// Returns the order list (응답 data 는 OrderItem 배열).
  ///
  /// [from]/[to] 는 'YYYY-MM-DD'. 둘 다 생략하면 서버 기본 창(최근 2주)을 탄다.
  Future<List<OrderModel>> getOrders({int? sellerId, String? from, String? to});

  /// POST /api/orders/sync?accountId={accountId} 또는 ?sellerId={sellerId}
  /// 동기화 후 갱신된 주문 목록 + 건수 요약을 반환한다.
  ///
  /// ⚠️ 서버 우선순위는 accountId > sellerId 다. 둘을 함께 보내면 응답 목록의
  /// 스코프가 헷갈리므로 **하나만** 보낸다(accountId 가 있으면 그것만).
  Future<OrderSyncResultModel> syncOrders({int? sellerId, int? accountId});

  /// POST /api/orders/sync/period?accountId={accountId}&from={from}&to={to}
  /// 계정 1건의 지정 기간을 불러온다. 응답에 목록은 없다(건수 요약만).
  Future<OrderSyncResultModel> syncPeriod({
    required int accountId,
    required String from,
    required String to,
  });

  /// GET /api/orders/sync/targets?sellerId={sellerId}
  /// 동기화 대상 채널(활성 + COUPANG) 목록. 자격증명은 응답에 포함되지 않는다.
  Future<List<SyncTargetModel>> getSyncTargets({int? sellerId});

  /// GET /api/orders/months → [{ym, count}] 최신순.
  /// 파라미터 없음 — 판매자 필터와 무관한 전체 기준이다(라벨 '(데이터 없음)' 판정 전용).
  Future<List<OrderMonthModel>> getOrderMonths();
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio dio;

  OrderRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<OrderModel>> getOrders({
    int? sellerId,
    String? from,
    String? to,
  }) async {
    try {
      // null 은 빼고 조립한다 — {'from': null} 을 보내면 Dio 가 '?from=' 을 붙이고
      // 서버는 400 이다(PLAN D5).
      final params = <String, dynamic>{
        if (sellerId != null) 'sellerId': sellerId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };
      final response = await dio.get(
        '/api/orders',
        queryParameters: params.isEmpty ? null : params,
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
  Future<OrderSyncResultModel> syncOrders({int? sellerId, int? accountId}) async {
    try {
      // body 없이 query param 으로 전송한다. 계정 단위 호출이면 accountId 만,
      // 아니면 sellerId 만 (서버 우선순위 accountId > sellerId).
      // 서버가 쿠팡 API를 실시간 조회 → 기본 30초를 초과할 수 있어 개별 연장.
      // 계정 1건 기준의 타임아웃이므로 전체 동기화보다 오히려 여유가 있다.
      final response = await dio.post(
        '/api/orders/sync',
        queryParameters: accountId != null
            ? {'accountId': accountId}
            : (sellerId != null ? {'sellerId': sellerId} : null),
        options: Options(
          receiveTimeout:
              const Duration(seconds: AppConstants.coupangReceiveTimeout),
        ),
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

  @override
  Future<OrderSyncResultModel> syncPeriod({
    required int accountId,
    required String from,
    required String to,
  }) async {
    try {
      // 셋 다 필수라 조건부 조립이 필요 없다.
      // syncOrders 와 동일하게 쿠팡 실시간 조회라 receiveTimeout 을 연장한다.
      final response = await dio.post(
        '/api/orders/sync/period',
        queryParameters: {
          'accountId': accountId,
          'from': from,
          'to': to,
        },
        options: Options(
          receiveTimeout:
              const Duration(seconds: AppConstants.coupangReceiveTimeout),
        ),
      );
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        final message = response.data is Map ? response.data['message'] : null;
        throw Exception(message?.toString() ?? 'Failed to sync period');
      }
      // 응답에 orders 가 없어도 fromJson 이 빈 리스트로 견딘다.
      return OrderSyncResultModel.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw Exception(body['message'].toString());
      }
      throw Exception(e.message ?? 'Failed to sync period');
    }
  }

  @override
  Future<List<SyncTargetModel>> getSyncTargets({int? sellerId}) async {
    try {
      // DB 조회만 하므로 타임아웃 연장 불필요.
      final response = await dio.get(
        '/api/orders/sync/targets',
        queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
      );
      final data = response.data['data'];
      if (data is! List) return [];
      return data
          .map((e) => SyncTargetModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch sync targets');
    }
  }

  @override
  Future<List<OrderMonthModel>> getOrderMonths() async {
    try {
      final response = await dio.get('/api/orders/months');
      final data = response.data['data'];
      if (data is! List) return [];
      return data
          .map((e) => OrderMonthModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch order months');
    }
  }
}
