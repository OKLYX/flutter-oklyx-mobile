import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_sync_result.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/purchase_list_item.dart';
import '../../domain/entities/unmapped_order.dart';

/// 화면 탭 (프론트 PurchaseTabs와 동일): 구매목록 / 구매완료내역.
enum PurchaseTab { active, completed }

abstract class PurchaseListState {}

/// 초기 상태 (진입 직후)
class PurchaseListInitial extends PurchaseListState {}

/// 최초 로드 중 (전체 화면 스피너)
class PurchaseListLoading extends PurchaseListState {}

/// 최초 로드 실패 (전체 화면 + 재시도)
class PurchaseListError extends PurchaseListState {
  final String message;

  PurchaseListError({required this.message});
}

/// Loaded state.
///
/// Sync / tab / detail controls must stay, so progress is a flag
/// ([isRefreshing] / [isSyncing] / [isLoadingCompleted]), not a separate state.
/// A transient failure travels in [actionError], is shown as a toast and is
/// cleared by the next state.
///
/// [filterSellerId] is the seller view filter (null = 「전체」, FEATURE_2610_09
/// D5) — reads only; sync always covers every seller (D19). [sellers] feeds the
/// filter, the intake card, the manual add dialog and [판매자 바꾸기].
///
/// [completedItems] is a lazy cache (null = not loaded) and [listStale] marks
/// the list for reload on the next entry — an action or a filter change on one
/// tab invalidates the other (D5).
///
/// [stockRecorded] is a **one-time notice** of a check-in — false shows the
/// "stock not recorded" toast while the stock link is on, then
/// `ClearStockNotice` clears it (otherwise the next rebuild shows it again).
///
/// [deletedManualItemId] is the manual line the last successful
/// `DeleteManualLine` removed (FEATURE_2610_09 D64). The detail page matches
/// it against its last seen lines to word its notice; a deleted id never
/// comes back, so it is not cleared.
///
/// [movedManualItemId] is the manual line the last successful
/// `ChangeManualSeller` moved to another seller (FEATURE_2610_09 D64). The
/// next successful share processing, [제거] or [판매자 바꾸기] replaces it (null
/// unless it is a move) — a moved line still exists under its new seller, so
/// a kept id would word a later notice wrongly. The detail page checks it
/// after [deletedManualItemId].
class PurchaseListLoaded extends PurchaseListState {
  final List<Seller> sellers;

  final PurchaseTab activeTab;

  /// Seller view filter; null = 「전체」 (FEATURE_2610_09 D5).
  final int? filterSellerId;

  // active 탭 데이터
  final List<PurchaseListItem> items;

  /// The 「오늘 넘김」 group (FEATURE_2610_09 D67).
  final List<PurchaseListItem> skippedToday;
  final List<UnmappedOrder> unmappedOrders;

  /// The list must reload on the next entry to the list tab (D5).
  final bool listStale;

  // completed 탭 데이터 (지연 로드)
  final List<PurchaseListItem>? completedItems;
  final bool isLoadingCompleted;

  // Completed tab filter (processing-day range, FEATURE_2610_09 D63). Defaults to
  // today (YYYY-MM-DD), applied by [조회].
  final String completedFrom;
  final String completedTo;

  final bool isRefreshing;
  final bool isSyncing;
  final OrderSyncResult? syncResult;
  final String? actionError;
  final bool? stockRecorded;
  final int? deletedManualItemId;
  final int? movedManualItemId;

  PurchaseListLoaded({
    required this.sellers,
    this.activeTab = PurchaseTab.active,
    this.filterSellerId,
    required this.items,
    this.skippedToday = const [],
    this.unmappedOrders = const [],
    this.listStale = false,
    this.completedItems,
    this.isLoadingCompleted = false,
    required this.completedFrom,
    required this.completedTo,
    this.isRefreshing = false,
    this.isSyncing = false,
    this.syncResult,
    this.actionError,
    this.stockRecorded,
    this.deletedManualItemId,
    this.movedManualItemId,
  });

  PurchaseListLoaded copyWith({
    List<Seller>? sellers,
    PurchaseTab? activeTab,
    int? filterSellerId,
    bool clearFilterSeller = false,
    List<PurchaseListItem>? items,
    List<PurchaseListItem>? skippedToday,
    List<UnmappedOrder>? unmappedOrders,
    bool? listStale,
    List<PurchaseListItem>? completedItems,
    bool clearCompleted = false,
    bool? isLoadingCompleted,
    String? completedFrom,
    String? completedTo,
    bool? isRefreshing,
    bool? isSyncing,
    OrderSyncResult? syncResult,
    bool clearSyncResult = false,
    String? actionError,
    bool clearActionError = false,
    bool? stockRecorded,
    bool clearStockRecorded = false,
    int? deletedManualItemId,
    int? movedManualItemId,
    bool clearMovedManualItem = false,
  }) {
    return PurchaseListLoaded(
      sellers: sellers ?? this.sellers,
      activeTab: activeTab ?? this.activeTab,
      filterSellerId:
          clearFilterSeller ? null : (filterSellerId ?? this.filterSellerId),
      items: items ?? this.items,
      skippedToday: skippedToday ?? this.skippedToday,
      unmappedOrders: unmappedOrders ?? this.unmappedOrders,
      listStale: listStale ?? this.listStale,
      completedItems:
          clearCompleted ? null : (completedItems ?? this.completedItems),
      isLoadingCompleted: isLoadingCompleted ?? this.isLoadingCompleted,
      completedFrom: completedFrom ?? this.completedFrom,
      completedTo: completedTo ?? this.completedTo,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSyncing: isSyncing ?? this.isSyncing,
      syncResult: clearSyncResult ? null : (syncResult ?? this.syncResult),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      stockRecorded:
          clearStockRecorded ? null : (stockRecorded ?? this.stockRecorded),
      deletedManualItemId: deletedManualItemId ?? this.deletedManualItemId,
      movedManualItemId: clearMovedManualItem
          ? null
          : (movedManualItemId ?? this.movedManualItemId),
    );
  }
}
