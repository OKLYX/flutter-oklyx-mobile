import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/order_item.dart';
import '../entities/order_sync_result.dart';

abstract class OrderRepository {
  /// 주문 목록 조회 (sellerId 미지정 시 전체)
  /// GET /api/orders?sellerId={sellerId}
  Future<Either<Failure, List<OrderItem>>> getOrders({int? sellerId});

  /// 주문 동기화 (외부 마켓플레이스 → 내부 DB)
  /// POST /api/orders/sync?sellerId={sellerId}
  Future<Either<Failure, OrderSyncResult>> syncOrders({int? sellerId});
}
