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

/// 조회 성공 상태.
///
/// 동기화/탭/펼침 컨트롤을 유지해야 하므로, 진행 상태는 별도 상태가 아닌
/// 플래그([isRefreshing]/[isSyncing]/[isLoadingCompleted])로 표현한다.
/// 일시적 실패는 [actionError]로 전달해 SnackBar로 표시한 뒤 다음 상태에서 비운다.
///
/// [sellers]는 툴바 필터가 아니라 **입고 카드 드롭다운**이 쓴다(PLAN 2609_29 D11) —
/// 판매자 스코프(selectedSellerId)는 없어졌고 조회·동기화는 항상 전체다.
///
/// [completedItems]는 지연 로드 캐시다(null = 미로드). active 탭에서 변이가
/// 일어나면 null로 무효화해 완료 탭 재진입 시 재조회한다.
///
/// [stockRecorded]는 입고 1회의 결과를 나르는 **1회성 안내**다 —
/// false 면 재고가 반영되지 않았다는 SnackBar 를 띄우고 곧바로
/// `ClearStockNotice`로 지운다(안 지우면 다음 리빌드에 또 뜬다).
class PurchaseListLoaded extends PurchaseListState {
  final List<Seller> sellers;

  final PurchaseTab activeTab;

  // active 탭 데이터
  final List<PurchaseListItem> items;
  final List<UnmappedOrder> unmappedOrders;
  final int? expandedProductId;

  // completed 탭 데이터 (지연 로드)
  final List<PurchaseListItem>? completedItems;
  final int? expandedCompletedProductId;
  final bool isLoadingCompleted;

  // completed 탭 필터 (구매일 기간). 기본값은 오늘(YYYY-MM-DD), '조회' 버튼으로 적용한다.
  final String completedFrom;
  final String completedTo;

  final bool isRefreshing;
  final bool isSyncing;
  final OrderSyncResult? syncResult;
  final String? actionError;
  final bool? stockRecorded;

  PurchaseListLoaded({
    required this.sellers,
    this.activeTab = PurchaseTab.active,
    required this.items,
    this.unmappedOrders = const [],
    this.expandedProductId,
    this.completedItems,
    this.expandedCompletedProductId,
    this.isLoadingCompleted = false,
    required this.completedFrom,
    required this.completedTo,
    this.isRefreshing = false,
    this.isSyncing = false,
    this.syncResult,
    this.actionError,
    this.stockRecorded,
  });

  PurchaseListLoaded copyWith({
    List<Seller>? sellers,
    PurchaseTab? activeTab,
    List<PurchaseListItem>? items,
    List<UnmappedOrder>? unmappedOrders,
    int? expandedProductId,
    bool clearExpanded = false,
    List<PurchaseListItem>? completedItems,
    bool clearCompleted = false,
    int? expandedCompletedProductId,
    bool clearExpandedCompleted = false,
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
  }) {
    return PurchaseListLoaded(
      sellers: sellers ?? this.sellers,
      activeTab: activeTab ?? this.activeTab,
      items: items ?? this.items,
      unmappedOrders: unmappedOrders ?? this.unmappedOrders,
      expandedProductId: clearExpanded
          ? null
          : (expandedProductId ?? this.expandedProductId),
      completedItems:
          clearCompleted ? null : (completedItems ?? this.completedItems),
      expandedCompletedProductId: clearExpandedCompleted
          ? null
          : (expandedCompletedProductId ?? this.expandedCompletedProductId),
      isLoadingCompleted: isLoadingCompleted ?? this.isLoadingCompleted,
      completedFrom: completedFrom ?? this.completedFrom,
      completedTo: completedTo ?? this.completedTo,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSyncing: isSyncing ?? this.isSyncing,
      syncResult: clearSyncResult ? null : (syncResult ?? this.syncResult),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      stockRecorded:
          clearStockRecorded ? null : (stockRecorded ?? this.stockRecorded),
    );
  }
}
