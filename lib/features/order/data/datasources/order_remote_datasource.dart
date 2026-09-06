import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import '../../domain/entities/order_sync_scope.dart';
import '../models/cancel_reason_option.dart';
import '../models/order_acknowledge_result.dart';
import '../models/order_cancel_result.dart';
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
  ///
  /// [scope] 는 조회할 주문 상태 범위. 기본 [OrderSyncScope.full] = 전 상태(오늘과 동일).
  /// 출고관리만 [OrderSyncScope.active] 를 준다.
  Future<OrderSyncResultModel> syncOrders({
    int? sellerId,
    int? accountId,
    OrderSyncScope scope = OrderSyncScope.full,
  });

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

  /// POST /api/admin/orders/acknowledge  body: {"orderItemIds":[...]}
  /// 발주처리(결제완료 → 상품준비중). 라인 id 만 보낸다 — 박스 dedupe·상태 필터는
  /// 서버가 한다(PLAN 2609_17 D1·D2).
  Future<OrderAcknowledgeResult> acknowledgeOrders(List<int> orderItemIds);

  /// GET /api/admin/orders/cancel-reasons → [{code,label}]
  /// 취소 사유 목록. **목록의 소유자는 서버다** — 모바일에 코드→라벨 상수를 두지 않는다
  /// (PLAN 2609_25 D4).
  Future<List<CancelReasonOption>> getCancelReasons();

  /// POST /api/admin/orders/cancel  body: {"lines":[{orderItemId,quantity}],"reason":"..."}
  /// 발송 전 주문 취소(결제완료 → 즉시취소, 상품준비중 → 출고중지).
  /// 계정→주문번호→박스 그룹핑과 상태 필터는 서버가 한다(D1·D2).
  Future<OrderCancelResult> cancelOrders(
    List<Map<String, dynamic>> lines,
    String reason,
  );
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
  Future<OrderSyncResultModel> syncOrders({
    int? sellerId,
    int? accountId,
    OrderSyncScope scope = OrderSyncScope.full,
  }) async {
    try {
      // body 없이 query param 으로 전송한다. 계정 단위 호출이면 accountId 만,
      // 아니면 sellerId 만 (서버 우선순위 accountId > sellerId).
      // 서버가 쿠팡 API를 실시간 조회 → 기본 30초를 초과할 수 있어 개별 연장.
      // 계정 1건 기준의 타임아웃이므로 전체 동기화보다 오히려 여유가 있다.
      final response = await dio.post(
        '/api/orders/sync',
        // scope 는 full 이면 키 자체를 보내지 않는다 — 구버전 서버에 붙어도 요청 모양이 같다.
        // sellerId 경로(구매목록·전체)는 항상 전 상태다(PLAN D4).
        queryParameters: accountId != null
            ? {
                'accountId': accountId,
                if (scope != OrderSyncScope.full) 'scope': scope.wireValue,
              }
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

  @override
  Future<OrderAcknowledgeResult> acknowledgeOrders(
    List<int> orderItemIds,
  ) async {
    // ⚠️ 이 메서드에만 try/catch 가 없다 — DioException 을 그대로 위로 올린다
    // (shipping_label_remote_datasource 와 같은 형태). 형제 메서드처럼 plain Exception 으로
    // 바꿔 던지면 OrderRepositoryImpl 의 `on DioException` 분기를 지나쳐
    // statusCode 가 사라지고, BLoC 의 403 판정이 영원히 false 가 된다.
    final response = await dio.post(
      '/api/admin/orders/acknowledge',
      data: {'orderItemIds': orderItemIds},
      options: Options(
        // 서버가 쿠팡 발주처리 API 를 실호출 → 기본 30초를 초과할 수 있어 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return OrderAcknowledgeResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<CancelReasonOption>> getCancelReasons() async {
    // ⚠️ 다른 조회 메서드와 달리 try/catch 로 감싸지 않는다 — 이 엔드포인트도 ADMIN 전용이라
    // USER 계정은 여기서 먼저 403 을 받는다. plain Exception 으로 바꿔 던지면 statusCode 가
    // 사라져 BLoC 이 403 을 "로드 실패" 로 오인하고 섹션을 계속 띄운다.
    final response = await dio.get('/api/admin/orders/cancel-reasons');
    final data = response.data['data'];
    if (data is! List) return [];
    return data
        .map((e) => CancelReasonOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderCancelResult> cancelOrders(
    List<Map<String, dynamic>> lines,
    String reason,
  ) async {
    // ⚠️ acknowledgeOrders 와 같은 규칙 — DioException 을 그대로 위로 올려 403 판정을 살린다.
    final response = await dio.post(
      '/api/admin/orders/cancel',
      data: {'lines': lines, 'reason': reason},
      options: Options(
        // 서버가 쿠팡 취소 API 를 실호출 → 기본 30초를 초과할 수 있어 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return OrderCancelResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
