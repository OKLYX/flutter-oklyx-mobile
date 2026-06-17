import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_sync_result.dart';

abstract class OrderListState {}

/// 초기 상태 (진입 직후)
class OrderListInitial extends OrderListState {}

/// 최초 로드 중 (전체 화면 스피너)
class OrderListLoading extends OrderListState {}

/// 최초 로드 실패 (전체 화면 + 재시도)
class OrderListError extends OrderListState {
  final String message;

  OrderListError({required this.message});
}

/// 조회 성공 상태.
///
/// 판매자 드롭다운/조회/동기화 컨트롤을 유지해야 하므로, 검색·동기화 진행은
/// 별도 상태가 아닌 [isSearching]/[isSyncing] 플래그로 표현한다(프론트의
/// isLoading/isSyncing과 동일). 일시적 실패는 [actionError]로 전달해
/// SnackBar로 표시한 뒤 다음 상태에서 비운다.
class OrderListLoaded extends OrderListState {
  final List<Seller> sellers;
  final int? selectedSellerId;
  final List<OrderItem> orders;
  final bool isSearching;
  final bool isSyncing;
  final String? actionError;
  final OrderSyncResult? syncResult;
  final String? lastSyncedAt;

  OrderListLoaded({
    required this.sellers,
    this.selectedSellerId,
    required this.orders,
    this.isSearching = false,
    this.isSyncing = false,
    this.actionError,
    this.syncResult,
    this.lastSyncedAt,
  });

  OrderListLoaded copyWith({
    List<Seller>? sellers,
    int? selectedSellerId,
    bool clearSelectedSeller = false,
    List<OrderItem>? orders,
    bool? isSearching,
    bool? isSyncing,
    String? actionError,
    bool clearActionError = false,
    OrderSyncResult? syncResult,
    bool clearSyncResult = false,
    String? lastSyncedAt,
  }) {
    return OrderListLoaded(
      sellers: sellers ?? this.sellers,
      selectedSellerId: clearSelectedSeller
          ? null
          : (selectedSellerId ?? this.selectedSellerId),
      orders: orders ?? this.orders,
      isSearching: isSearching ?? this.isSearching,
      isSyncing: isSyncing ?? this.isSyncing,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      syncResult: clearSyncResult ? null : (syncResult ?? this.syncResult),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
