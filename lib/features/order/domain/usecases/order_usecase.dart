import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/order_item.dart';
import '../entities/order_period.dart';
import '../entities/order_sync_result.dart';
import '../entities/order_sync_scope.dart';
import '../entities/sync_target.dart';
import '../repositories/order_repository.dart';

/// 주문 조회/동기화 UseCase (프론트 OrderUseCase와 동일하게 Repository에 위임)
class OrderUseCase {
  final OrderRepository repository;

  OrderUseCase({required this.repository});

  /// [from]/[to] 는 'YYYY-MM-DD'. 미지정 시 서버 기본 창(최근 2주).
  Future<Either<Failure, List<OrderItem>>> getOrders({
    int? sellerId,
    String? from,
    String? to,
  }) {
    return repository.getOrders(sellerId: sellerId, from: from, to: to);
  }

  /// [accountId] 를 주면 그 계정 1건만 동기화한다(진행 다이얼로그의 계정 단위 루프).
  /// [scope] 기본값은 전 상태 — 출고관리만 [OrderSyncScope.active].
  Future<Either<Failure, OrderSyncResult>> syncOrders({
    int? sellerId,
    int? accountId,
    OrderSyncScope scope = OrderSyncScope.full,
  }) {
    return repository.syncOrders(
      sellerId: sellerId,
      accountId: accountId,
      scope: scope,
    );
  }

  /// 계정 1건의 지정 기간을 쿠팡에서 백필한다(빈 달 불러오기).
  Future<Either<Failure, OrderSyncResult>> syncPeriod({
    required int accountId,
    required String from,
    required String to,
  }) {
    return repository.syncPeriod(accountId: accountId, from: from, to: to);
  }

  Future<Either<Failure, List<SyncTarget>>> getSyncTargets({int? sellerId}) {
    return repository.getSyncTargets(sellerId: sellerId);
  }

  Future<Either<Failure, List<OrderMonth>>> getOrderMonths() {
    return repository.getOrderMonths();
  }
}
