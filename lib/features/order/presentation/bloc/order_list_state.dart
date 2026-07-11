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

  /// 선택된 상태 필터 (null = 전체). 프론트 OrderContainer.selectedStatus와 동일.
  final String? selectedStatus;

  /// Shipping Label(주문목록) xlsx 다운로드 진행 중 여부.
  final bool isDownloading;

  /// 다운로드 성공 시 저장된 파일 경로 (transient — SnackBar 노출용).
  /// [syncResult]와 동일하게 다음 액션 시작 시 clearDownloadResult 로 비운다.
  final String? downloadSavedPath;

  OrderListLoaded({
    required this.sellers,
    this.selectedSellerId,
    required this.orders,
    this.isSearching = false,
    this.isSyncing = false,
    this.actionError,
    this.syncResult,
    this.lastSyncedAt,
    this.selectedStatus,
    this.isDownloading = false,
    this.downloadSavedPath,
  });

  /// 상태별 주문 건수 (필터 버튼 배지용). 선택과 무관하게 전체 주문 기준.
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 선택된 상태로 거른 주문 목록 (null = 전체).
  List<OrderItem> get filteredOrders => selectedStatus == null
      ? orders
      : orders.where((o) => o.status == selectedStatus).toList();

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
    String? selectedStatus,
    bool clearSelectedStatus = false,
    bool? isDownloading,
    String? downloadSavedPath,
    bool clearDownloadResult = false,
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
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      isDownloading: isDownloading ?? this.isDownloading,
      downloadSavedPath: clearDownloadResult
          ? null
          : (downloadSavedPath ?? this.downloadSavedPath),
    );
  }
}
