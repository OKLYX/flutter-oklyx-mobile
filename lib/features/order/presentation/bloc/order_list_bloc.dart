import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/entities/order_period.dart';
import '../../domain/entities/order_sync_result.dart';
import '../../domain/entities/sync_target.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_list_event.dart';
import 'order_list_state.dart';

/// 주문내역 조회/동기화 BLoC
///
/// 프론트 OrderContainer와 동일하게 동작한다:
/// - 진입 시 판매자 목록 + 전체 주문 로드 ([LoadOrders])
/// - 판매자 선택 ([SelectSeller]) 후 조회 ([SearchOrders])
/// - 외부 마켓플레이스 동기화 ([SyncOrders]): 대상 채널을 조회해 **계정 단위로 순차 호출**하고,
///   진행 상황을 [OrderListLoaded.syncChannels]로 노출한다(진행 다이얼로그).
///   끝나면 목록을 1회 재조회하고, 채널 상태 배너를 서버 상태로 다시 낙인한다.
///
/// 판매자 목록은 기존 seller 기능의 [GetSellersUseCase]를 재사용한다.
class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  final OrderUseCase orderUseCase;
  final GetSellersUseCase getSellersUseCase;

  OrderListBloc({
    required this.orderUseCase,
    required this.getSellersUseCase,
  }) : super(OrderListInitial()) {
    on<LoadOrders>(_onLoad);
    on<SelectSeller>(_onSelectSeller);
    on<SearchOrders>(_onSearch);
    on<SyncOrders>(_onSync);
    on<CancelSync>((_, __) => _cancelRequested = true);
    on<RetryFailedChannels>(_onRetryFailed);
    on<SyncSelectedChannels>(_onSyncSelected);
    on<SelectStatus>(_onSelectStatus);
    on<SelectPeriod>(_onSelectPeriod);
    on<ChangeSearchField>(_onChangeSearchField);
    on<ChangeSearchTerm>(_onChangeSearchTerm);
  }

  // Cancellation is cooperative: the in-flight account request is NOT aborted (the server keeps
  // going anyway), we only stop before the next one (PLAN D12).
  bool _cancelRequested = false;

  Future<void> _onLoad(LoadOrders event, Emitter<OrderListState> emit) async {
    emit(OrderListLoading());

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백 (프론트와 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    // 기본값이 kRecentPeriod 라 from/to 를 보내지 않는다 = 서버 기본 창.
    final ordersResult = await orderUseCase.getOrders();
    // 첫 진입에 지난 동기화 실패를 배너로 낙인한다(조회 실패는 비치명적 — 빈 리스트).
    final targets = await _fetchTargets(null);
    // 기간 라벨의 '(데이터 없음)' 판정용. 실패해도 화면을 막지 않는다 —
    // 빈 집합이면 전 옵션이 '(데이터 없음)' 으로 보일 뿐이다.
    final monthsResult = await orderUseCase.getOrderMonths();
    final monthsWithData =
        monthsResult.fold((_) => <String>{}, (rows) => rows.map((e) => e.ym).toSet());
    ordersResult.fold(
      (failure) => emit(OrderListError(message: failure.message)),
      (orders) => emit(OrderListLoaded(
        sellers: sellers,
        orders: orders,
        syncTargets: targets,
        monthsWithData: monthsWithData,
      )),
    );
  }

  void _onSelectSeller(SelectSeller event, Emitter<OrderListState> emit) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
    ));
  }

  void _onSelectStatus(SelectStatus event, Emitter<OrderListState> emit) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(
      selectedStatus: event.status,
      clearSelectedStatus: event.status == null,
    ));
  }

  /// 기간 선택 — 값만 바꾼다. 목록 반영은 [SearchOrders](조회 버튼)에서(PLAN D8).
  void _onSelectPeriod(SelectPeriod event, Emitter<OrderListState> emit) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(selectedPeriod: event.period));
  }

  /// 검색 대상 칩 변경 — 클라이언트 필터라 서버를 부르지 않는다.
  void _onChangeSearchField(
    ChangeSearchField event,
    Emitter<OrderListState> emit,
  ) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(searchField: event.field));
  }

  /// 검색어 입력 — 클라이언트 필터라 서버를 부르지 않는다(PLAN D9).
  void _onChangeSearchTerm(
    ChangeSearchTerm event,
    Emitter<OrderListState> emit,
  ) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(searchTerm: event.term));
  }

  Future<void> _onSearch(
    SearchOrders event,
    Emitter<OrderListState> emit,
  ) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing) return;

    emit(current.copyWith(
        isSearching: true, clearActionError: true, clearSyncResult: true));

    final range = toPeriodRange(current.selectedPeriod);
    final result = await orderUseCase.getOrders(
      sellerId: current.selectedSellerId,
      from: range?.from,
      to: range?.to,
    );
    // 목록 스코프가 바뀌는 시점 = 배너 스코프가 바뀌는 시점.
    final targets = await _fetchTargets(current.selectedSellerId);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(current.copyWith(
        isSearching: false,
        orders: const [],
        actionError: failure.message,
        syncTargets: targets,
      )),
      // 실패 경로에는 appliedPeriod 를 넣지 않는다 — 목록을 비우므로 배너는
      // 마지막으로 성공 조회된 기간을 계속 따라가는 게 맞다.
      (orders) => emit(current.copyWith(
          isSearching: false,
          orders: orders,
          syncTargets: targets,
          appliedPeriod: current.selectedPeriod)),
    );
  }

  Future<void> _onSync(SyncOrders event, Emitter<OrderListState> emit) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing) return;

    final targetsResult =
        await orderUseCase.getSyncTargets(sellerId: current.selectedSellerId);
    if (emit.isDone) return;
    // 조회 실패와 '대상 0건' 은 원인이 다르므로 문구를 구분한다.
    final targets = targetsResult.fold((f) => null, (t) => t);
    if (targets == null) {
      emit(current.copyWith(actionError: '동기화할 채널을 불러오지 못했습니다.'));
      return;
    }
    if (targets.isEmpty) {
      emit(current.copyWith(actionError: '동기화할 채널이 없습니다.'));
      return;
    }
    await _runSync(targets, emit);
  }

  Future<void> _onRetryFailed(
    RetryFailedChannels event,
    Emitter<OrderListState> emit,
  ) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    final failed = current.syncChannels
        .where((c) => c.state == ChannelSyncState.failed)
        .map((c) => c.target)
        .toList();
    if (failed.isEmpty) return;
    await _runSync(failed, emit);
  }

  Future<void> _onSyncSelected(
    SyncSelectedChannels event,
    Emitter<OrderListState> emit,
  ) async {
    if (event.targets.isEmpty) return;
    await _runSync(event.targets, emit);
  }

  /// 계정 단위 순차 동기화. 진행 상태를 emit 하며 돌고, 끝나면 목록과 배너를 갱신한다.
  Future<void> _runSync(
    List<SyncTarget> targets,
    Emitter<OrderListState> emit,
  ) async {
    final start = state;
    if (start is! OrderListLoaded) return;
    // 재시도 경로에는 _onSync 의 가드가 없으므로 여기서 같은 가드를 다시 건다
    // (다이얼로그가 떠 있는 동안 상태가 바뀌었을 수 있다).
    if (start.isSearching || start.isSyncing) return;

    _cancelRequested = false;
    var channels = targets
        .map((t) => ChannelProgress(target: t, state: ChannelSyncState.pending))
        .toList();
    var loaded = start.copyWith(
      isSyncing: true,
      clearActionError: true,
      clearSyncResult: true,
      syncChannels: channels,
      syncDoneCount: 0,
      syncCanceled: false,
    );
    emit(loaded);

    var newCount = 0, updatedCount = 0, canceledCount = 0;
    // 마지막 성공 응답의 **서버** 시각. 성공 0건이면 null → 기존 값 유지.
    String? syncedAt;

    for (var i = 0; i < targets.length; i++) {
      if (_cancelRequested || emit.isDone) break;
      channels = _mark(channels, i, ChannelSyncState.running);
      emit(loaded = loaded.copyWith(syncChannels: channels));

      final result =
          await orderUseCase.syncOrders(accountId: targets[i].accountId);
      // 페이지 이탈로 bloc 이 닫힘 — 더 emit 하면 StateError.
      if (emit.isDone) return;
      result.fold(
        (failure) => channels = _mark(
            channels, i, ChannelSyncState.failed, _syncErrorMessage(failure)),
        (sync) {
          newCount += sync.newOrders;
          updatedCount += sync.updatedOrders;
          canceledCount += sync.canceledUpdated;
          syncedAt = sync.syncedAt;
          channels = _mark(channels, i, ChannelSyncState.success);
        },
      );
      emit(loaded = loaded.copyWith(
          syncChannels: channels, syncDoneCount: i + 1));
    }

    // 루프 응답의 orders 는 계정 스코프라 쓰지 않는다 — 끝나고 목록 1회 재조회(PLAN D11).
    // 🔴 기준은 appliedPeriod 다(selectedPeriod 가 아니다) — 동기화는 화면에 떠 있는 기간을
    // 그대로 다시 읽는 것이라, 고르기만 한 기간이 [조회] 없이 반영되면 D8 이 깨진다.
    // (동기화 창 자체는 14일 고정, PLAN D1.)
    final range = toPeriodRange(loaded.appliedPeriod);
    final orders = await orderUseCase.getOrders(
      sellerId: loaded.selectedSellerId,
      from: range?.from,
      to: range?.to,
    );
    // 채널의 진실은 서버 상태다. 위 루프의 success 는 HTTP 결과일 뿐이라 PARTIAL
    // (주문 조회는 됐고 취소 보정이 실패한 계정)을 못 잡는다 → 대상을 다시 조회해 배너를 낙인한다.
    final after = await _fetchTargets(loaded.selectedSellerId);
    if (emit.isDone) return;

    // 실패 사유도 서버가 낙인한 문구로 교체한다(PLAN D18): 동기화 실패는 서버 catch-all 이
    // "Internal server error" 로 답해 HTTP 본문에는 진짜 사유가 없다.
    channels = channels.map((c) {
      if (c.state != ChannelSyncState.failed) return c;
      final recorded = after
          .where((t) => t.accountId == c.target.accountId)
          .map((t) => t.lastSyncError)
          .firstWhere((e) => e != null, orElse: () => null);
      return recorded == null ? c : c.copyWith(error: recorded);
    }).toList();

    emit(loaded.copyWith(
      isSyncing: false,
      syncCanceled: _cancelRequested,
      syncChannels: channels,
      orders: orders.fold((_) => loaded.orders, (o) => o),
      syncResult: OrderSyncResult(
        syncedAt: syncedAt ?? '',
        newOrders: newCount,
        updatedOrders: updatedCount,
        canceledUpdated: canceledCount,
        orders: const [],
      ),
      // null 이면 copyWith 가 기존 값을 유지한다(전부 실패/즉시 취소).
      lastSyncedAt: syncedAt,
      syncTargets: after,
    ));
  }

  /// 인덱스 [index] 행만 갱신한 새 리스트를 돌려준다.
  List<ChannelProgress> _mark(
    List<ChannelProgress> channels,
    int index,
    ChannelSyncState state, [
    String? error,
  ]) {
    return [
      for (var i = 0; i < channels.length; i++)
        i == index ? channels[i].copyWith(state: state, error: error) : channels[i]
    ];
  }

  /// 배너용 채널 상태 조회. 실패하면 빈 리스트 — 배너만 숨기고 화면 전체를 에러로 만들지 않는다.
  Future<List<SyncTarget>> _fetchTargets(int? sellerId) async {
    final result = await orderUseCase.getSyncTargets(sellerId: sellerId);
    return result.fold((_) => <SyncTarget>[], (targets) => targets);
  }

  // 데이터소스가 Exception 을 던지고 repository 가 e.toString() 으로 감싸므로
  // 문구가 'Exception: …' 로 온다 — 접두어만 떼고 서버 문구를 그대로 노출한다.
  String _syncErrorMessage(Failure failure) {
    const prefix = 'Exception: ';
    final message = failure.message;
    return message.startsWith(prefix)
        ? message.substring(prefix.length)
        : message;
  }
}
