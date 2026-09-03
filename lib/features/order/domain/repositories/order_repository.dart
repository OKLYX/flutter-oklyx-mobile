import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/order_item.dart';
import '../entities/order_period.dart';
import '../entities/order_sync_result.dart';
import '../entities/sync_target.dart';

abstract class OrderRepository {
  /// 주문 목록 조회 (sellerId 미지정 시 전체)
  /// GET /api/orders?sellerId={sellerId}&from={from}&to={to}
  /// [from]/[to] 미지정 시 서버 기본 창(최근 2주).
  Future<Either<Failure, List<OrderItem>>> getOrders({
    int? sellerId,
    String? from,
    String? to,
  });

  /// 주문 동기화 (외부 마켓플레이스 → 내부 DB)
  /// POST /api/orders/sync?accountId={accountId} 또는 ?sellerId={sellerId}
  /// [accountId] 를 주면 그 계정만 동기화한다(둘 중 하나만 전송).
  Future<Either<Failure, OrderSyncResult>> syncOrders({
    int? sellerId,
    int? accountId,
  });

  /// 기간 백필 (빈 달을 쿠팡에서 불러오기)
  /// POST /api/orders/sync/period?accountId={accountId}&from={from}&to={to}
  /// 계정 1건 단위. 응답은 건수 요약만이고 목록은 포함되지 않는다.
  Future<Either<Failure, OrderSyncResult>> syncPeriod({
    required int accountId,
    required String from,
    required String to,
  });

  /// 동기화 대상 채널 목록 (진행 표시·재시도·상태 배너용)
  /// GET /api/orders/sync/targets?sellerId={sellerId}
  Future<Either<Failure, List<SyncTarget>>> getSyncTargets({int? sellerId});

  /// 월별 주문 건수 (기간 드롭다운 라벨의 '(데이터 없음)' 판정용)
  /// GET /api/orders/months
  Future<Either<Failure, List<OrderMonth>>> getOrderMonths();
}
