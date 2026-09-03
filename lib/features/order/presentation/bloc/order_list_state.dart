import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_period.dart';
import '../../domain/entities/order_sync_result.dart';
import '../../domain/entities/sync_target.dart';

abstract class OrderListState {}

/// 채널 1개의 동기화 진행 상태.
///
/// ⚠️ **이번 실행의 HTTP 결과만** 표현한다 — 서버가 낙인한 상태(SUCCESS/PARTIAL/FAILED)와
/// 다르다. 계정이 200 을 주고도 서버는 PARTIAL(취소 보정 실패)일 수 있으므로, 목록 상단
/// 배너는 이 값이 아니라 [OrderListLoaded.syncTargets] 로 그린다(PLAN D8/D18).
enum ChannelSyncState { pending, running, success, failed }

/// 진행 다이얼로그의 행 1개.
class ChannelProgress {
  final SyncTarget target;
  final ChannelSyncState state;
  final String? error;

  const ChannelProgress({
    required this.target,
    required this.state,
    this.error,
  });

  ChannelProgress copyWith({ChannelSyncState? state, String? error}) {
    return ChannelProgress(
      target: target,
      state: state ?? this.state,
      error: error ?? this.error,
    );
  }
}

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

  /// 진행 다이얼로그 전용 — 이번 동기화 실행의 채널별 진행 상태.
  /// 진행률 분모는 반드시 이 리스트의 길이다(판매자 수 아님, PLAN D3).
  final List<ChannelProgress> syncChannels;

  /// 진행률 분자 — 응답을 받은 채널 수.
  final int syncDoneCount;

  /// 사용자의 취소로 중단됐는지 (리포트 문구용).
  final bool syncCanceled;

  /// 배너 전용 — 서버가 영속한 채널 상태. [syncChannels]와 **겸용하지 않는다**:
  /// 진행 리스트에는 PARTIAL 이 없어 서버 낙인과 lastSyncError 가 사라진다(PLAN D8/D18).
  final List<SyncTarget> syncTargets;

  /// 드롭다운에 보이는 '고른 값'. [조회] 전엔 목록에 반영되지 않는다(PLAN D8).
  final String selectedPeriod;

  /// 🔴 지금 목록이 담고 있는 기간 — stale 배너는 이쪽을 본다.
  /// [selectedPeriod] 로 배너를 그리면, 8월을 조회한 뒤 드롭다운만 '최근 2주'로 되돌렸을 때
  /// 배너가 사라지는데 목록은 그대로 8월이다(반대 방향도 똑같이 어긋난다).
  final String appliedPeriod;

  /// 검색 대상 칩 (고객명 ↔ 주문번호).
  final OrderSearchField searchField;

  /// 검색어. 빈 문자열이 곧 '검색 없음'이다(clear 플래그 불필요).
  final String searchTerm;

  /// 주문이 있는 달('YYYY-MM') — 기간 라벨의 '(데이터 없음)' 판정용.
  final Set<String> monthsWithData;

  /// 백필을 물어볼 대상 라벨('2026년 8월'). null 이면 다이얼로그를 띄우지 않는다.
  /// 월 조회 결과가 0건일 때만 1회 채워진다(PLAN D1·D10).
  final String? backfillPrompt;

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
    this.syncChannels = const [],
    this.syncDoneCount = 0,
    this.syncCanceled = false,
    this.syncTargets = const [],
    this.selectedPeriod = kRecentPeriod,
    this.appliedPeriod = kRecentPeriod,
    this.searchField = OrderSearchField.customer,
    this.searchTerm = '',
    this.monthsWithData = const {},
    this.backfillPrompt,
  });

  /// 검색어·칩으로 거른 목록. [statusCounts]·[filteredOrders] 의 **공통 소스**다.
  List<OrderItem> get searchedOrders => orders
      .where((o) => matchesOrderSearch(o, searchField, searchTerm))
      .toList();

  /// 상태별 주문 건수 (필터 버튼 배지용). 상태 선택과 무관하지만 **검색은 반영**한다
  /// — 배지가 목록과 어긋나면 안 된다(PLAN D13).
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    for (final order in searchedOrders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 마지막 동기화가 완료되지 않은 채널(배너 대상). 서버 상태 기준 — PARTIAL/FAILED.
  List<SyncTarget> get nonSuccessTargets => syncTargets
      .where((t) => t.lastSyncStatus != null && t.lastSyncStatus != 'SUCCESS')
      .toList();

  /// 검색 결과를 선택된 상태로 다시 거른 목록 (null = 전체). 순서 = 검색 → 상태(PLAN D13).
  List<OrderItem> get filteredOrders => selectedStatus == null
      ? searchedOrders
      : searchedOrders.where((o) => o.status == selectedStatus).toList();

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
    List<ChannelProgress>? syncChannels,
    int? syncDoneCount,
    bool? syncCanceled,
    List<SyncTarget>? syncTargets,
    String? selectedPeriod,
    String? appliedPeriod,
    OrderSearchField? searchField,
    String? searchTerm,
    Set<String>? monthsWithData,
    String? backfillPrompt,
    bool clearBackfillPrompt = false,
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
      // clear* 플래그 불필요 — 네 값 모두 새 값을 대입해 초기화한다(빈 리스트/0/false).
      syncChannels: syncChannels ?? this.syncChannels,
      syncDoneCount: syncDoneCount ?? this.syncDoneCount,
      syncCanceled: syncCanceled ?? this.syncCanceled,
      syncTargets: syncTargets ?? this.syncTargets,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      appliedPeriod: appliedPeriod ?? this.appliedPeriod,
      searchField: searchField ?? this.searchField,
      // '' 가 곧 "검색 없음" 이라 clear 플래그가 필요 없다.
      searchTerm: searchTerm ?? this.searchTerm,
      monthsWithData: monthsWithData ?? this.monthsWithData,
      // ⚠️ clear 플래그가 없으면 한 번 뜬 프롬프트가 영원히 사라지지 않는다(actionError 와 같은 함정).
      backfillPrompt: clearBackfillPrompt
          ? null
          : (backfillPrompt ?? this.backfillPrompt),
    );
  }
}
