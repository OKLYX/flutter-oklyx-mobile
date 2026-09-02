import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/order_item.dart';
import '../entities/order_sync_result.dart';
import '../entities/sync_target.dart';

abstract class OrderRepository {
  /// 주문 목록 조회 (sellerId 미지정 시 전체)
  /// GET /api/orders?sellerId={sellerId}
  Future<Either<Failure, List<OrderItem>>> getOrders({int? sellerId});

  /// 주문 동기화 (외부 마켓플레이스 → 내부 DB)
  /// POST /api/orders/sync?accountId={accountId} 또는 ?sellerId={sellerId}
  /// [accountId] 를 주면 그 계정만 동기화한다(둘 중 하나만 전송).
  Future<Either<Failure, OrderSyncResult>> syncOrders({
    int? sellerId,
    int? accountId,
  });

  /// 동기화 대상 채널 목록 (진행 표시·재시도·상태 배너용)
  /// GET /api/orders/sync/targets?sellerId={sellerId}
  Future<Either<Failure, List<SyncTarget>>> getSyncTargets({int? sellerId});
}
