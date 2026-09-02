import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/order_item.dart';
import '../entities/order_sync_result.dart';
import '../entities/sync_target.dart';
import '../repositories/order_repository.dart';

/// 주문 조회/동기화 UseCase (프론트 OrderUseCase와 동일하게 Repository에 위임)
class OrderUseCase {
  final OrderRepository repository;

  OrderUseCase({required this.repository});

  Future<Either<Failure, List<OrderItem>>> getOrders({int? sellerId}) {
    return repository.getOrders(sellerId: sellerId);
  }

  /// [accountId] 를 주면 그 계정 1건만 동기화한다(진행 다이얼로그의 계정 단위 루프).
  Future<Either<Failure, OrderSyncResult>> syncOrders({
    int? sellerId,
    int? accountId,
  }) {
    return repository.syncOrders(sellerId: sellerId, accountId: accountId);
  }

  Future<Either<Failure, List<SyncTarget>>> getSyncTargets({int? sellerId}) {
    return repository.getSyncTargets(sellerId: sellerId);
  }
}
