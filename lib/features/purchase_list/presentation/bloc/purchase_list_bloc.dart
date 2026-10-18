import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/usecases/add_manual_item_usecase.dart';
import '../../domain/usecases/adjust_manual_qty_usecase.dart';
import '../../domain/usecases/change_manual_seller_usecase.dart';
import '../../domain/usecases/check_purchase_share_usecase.dart';
import '../../domain/usecases/delete_manual_item_usecase.dart';
import '../../domain/usecases/extract_purchase_list_usecase.dart';
import '../../domain/usecases/get_completed_purchase_list_usecase.dart';
import '../../domain/usecases/get_purchase_list_usecase.dart';
import '../../domain/usecases/record_purchase_usecase.dart';
import 'purchase_list_event.dart';
import 'purchase_list_state.dart';

/// Purchase list BLoC (PLAN 2609_29 · FEATURE_2610_09)
///
/// - Entry: sellers + purchase list (+ 「오늘 넘김」 + unmapped orders) ([LoadPurchaseList])
/// - Order sync ([SyncOrders]) = sync + re-extract, then a reload with the
///   current filter (no separate [재적재], D12 · FEATURE_2610_09 D4)
/// - Tab switch ([SwitchTab]) — completed is lazy and cached; a stale list
///   reloads on entry
/// - Seller filter ([ChangeSellerFilter]) — the current tab reloads, the other
///   one on its next entry (D5)
/// - Check-in ([RecordPurchase]) / manual quantity ([AdjustManualQty]) / manual
///   add ([AddManualItem]) / manual seller ([ChangeManualSeller]) / manual
///   delete ([DeleteManualLine]) / share processing ([CheckShare] ·
///   [CancelShareCheck]) — then the current tab reloads
///
/// 🔴 The seller filter narrows the reads only — sync always covers every seller
/// (FEATURE_2610_09 D19).
/// 🔴 Recent purchases are not kept in this BLoC (D9) — one state per product
/// would tangle with the list state. The intake card calls
/// `GetRecentPurchasesUseCase` itself and keeps the rows locally.
///
/// Sellers come from the seller feature's [GetSellersUseCase], order sync from
/// the order feature's [OrderUseCase].
class PurchaseListBloc extends Bloc<PurchaseListEvent, PurchaseListState> {
  final GetPurchaseListUseCase getPurchaseListUseCase;
  final ExtractPurchaseListUseCase extractPurchaseListUseCase;
  final GetCompletedPurchaseListUseCase getCompletedPurchaseListUseCase;
  final RecordPurchaseUseCase recordPurchaseUseCase;
  final AdjustManualQtyUseCase adjustManualQtyUseCase;
  final AddManualItemUseCase addManualItemUseCase;
  final ChangeManualSellerUseCase changeManualSellerUseCase;
  final DeleteManualItemUseCase deleteManualItemUseCase;
  final CheckPurchaseShareUseCase checkPurchaseShareUseCase;
  final GetSellersUseCase getSellersUseCase;
  final OrderUseCase orderUseCase;

  PurchaseListBloc({
    required this.getPurchaseListUseCase,
    required this.extractPurchaseListUseCase,
    required this.getCompletedPurchaseListUseCase,
    required this.recordPurchaseUseCase,
    required this.adjustManualQtyUseCase,
    required this.addManualItemUseCase,
    required this.changeManualSellerUseCase,
    required this.deleteManualItemUseCase,
    required this.checkPurchaseShareUseCase,
    required this.getSellersUseCase,
    required this.orderUseCase,
  }) : super(PurchaseListInitial()) {
    on<LoadPurchaseList>(_onLoad);
    on<SyncOrders>(_onSync);
    on<SwitchTab>(_onSwitchTab);
    on<ApplyCompletedFilter>(_onApplyCompletedFilter);
    on<ResetCompletedFilter>(_onResetCompletedFilter);
    on<RecordPurchase>(_onRecordPurchase);
    on<ClearStockNotice>(_onClearStockNotice);
    on<AdjustManualQty>(_onAdjustManualQty);
    on<AddManualItem>(_onAddManualItem);
    on<ChangeSellerFilter>(_onChangeSellerFilter);
    on<CheckShare>(_onCheckShare);
    on<CancelShareCheck>(_onCancelShareCheck);
    on<ChangeManualSeller>(_onChangeManualSeller);
    on<DeleteManualLine>(_onDeleteManualLine);
  }

  bool _busy(PurchaseListLoaded s) => s.isRefreshing || s.isSyncing;

  /// 로컬 타임존 기준 오늘(YYYY-MM-DD). 완료내역 필터 기본값으로 사용한다.
  String _todayStr() {
    final d = DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _onLoad(
    LoadPurchaseList event,
    Emitter<PurchaseListState> emit,
  ) async {
    emit(PurchaseListLoading());

    // 판매자 목록 실패는 비치명적: 입고 카드 드롭다운이 빈 채로 뜬다.
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    // D53: exactly one seller = that seller picked (the filter is hidden).
    final soleSellerId = sellers.length == 1 ? sellers.first.id : null;
    final listResult = await getPurchaseListUseCase(sellerId: soleSellerId);
    listResult.fold(
      (failure) => emit(PurchaseListError(message: failure.message)),
      (result) => emit(PurchaseListLoaded(
        sellers: sellers,
        filterSellerId: soleSellerId,
        items: result.items,
        skippedToday: result.skippedToday,
        unmappedOrders: result.unmappedOrders,
        completedFrom: _todayStr(),
        completedTo: _todayStr(),
      )),
    );
  }

  /// Order sync: the order feature syncs, the list re-extracts, then the list
  /// reloads with the current filter (FEATURE_2610_09 D4). Sync always covers
  /// every seller (D19).
  Future<void> _onSync(SyncOrders event, Emitter<PurchaseListState> emit) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(
      isSyncing: true,
      clearActionError: true,
      clearSyncResult: true,
    ));

    final syncResult = await orderUseCase.syncOrders();
    await syncResult.fold(
      (failure) async => emit(current.copyWith(
        isSyncing: false,
        actionError: failure.message,
      )),
      (sync) async {
        final extracted = await extractPurchaseListUseCase();
        final extractFailure = extracted.fold((f) => f, (_) => null);
        if (extractFailure != null) {
          emit(current.copyWith(
            isSyncing: false,
            syncResult: sync,
            actionError: extractFailure.message,
          ));
          return;
        }
        // D4: the extract answers with 「전체」 — reload with the filter instead.
        final reloaded =
            await getPurchaseListUseCase(sellerId: current.filterSellerId);
        reloaded.fold(
          (failure) => emit(current.copyWith(
            isSyncing: false,
            syncResult: sync,
            actionError: failure.message,
          )),
          (res) => emit(current.copyWith(
            isSyncing: false,
            syncResult: sync,
            items: res.items,
            skippedToday: res.skippedToday,
            unmappedOrders: res.unmappedOrders,
            clearCompleted: true,
          )),
        );
      },
    );
  }

  Future<void> _onSwitchTab(
    SwitchTab event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;

    emit(current.copyWith(activeTab: event.tab));

    // D5: a list marked stale by the completed tab reloads on entry.
    if (event.tab == PurchaseTab.active && current.listStale) {
      await _reloadList(
        current.copyWith(activeTab: PurchaseTab.active, listStale: false),
        emit,
      );
      return;
    }

    // 완료 탭 진입 시 미로드 캐시면 현재 완료내역 필터로 지연 로드한다.
    if (event.tab == PurchaseTab.completed &&
        current.completedItems == null &&
        !current.isLoadingCompleted) {
      await _loadCompleted(
        current.copyWith(activeTab: PurchaseTab.completed),
        current.completedFrom,
        current.completedTo,
        emit,
      );
    }
  }

  /// 완료내역 필터 적용 → 해당 기간으로 재조회 (펼침 초기화).
  Future<void> _onApplyCompletedFilter(
    ApplyCompletedFilter event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.isLoadingCompleted) return;

    await _loadCompleted(current, event.from, event.to, emit);
  }

  /// Completed filter reset → reload with today as the processing-day range.
  Future<void> _onResetCompletedFilter(
    ResetCompletedFilter event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.isLoadingCompleted) return;

    final today = _todayStr();
    await _loadCompleted(current, today, today, emit);
  }

  /// Loads the completed list for the given processing-day range
  /// (FEATURE_2610_09 D63) and the seller filter. The range stays in the
  /// state so it survives tab switches.
  Future<void> _loadCompleted(
    PurchaseListLoaded base,
    String from,
    String to,
    Emitter<PurchaseListState> emit,
  ) async {
    emit(base.copyWith(
      completedFrom: from,
      completedTo: to,
      isLoadingCompleted: true,
      clearActionError: true,
    ));

    final result = await getCompletedPurchaseListUseCase(
      from.isEmpty ? null : from,
      to.isEmpty ? null : to,
      sellerId: base.filterSellerId,
    );
    final latest = state;
    if (latest is! PurchaseListLoaded) return;
    result.fold(
      (failure) => emit(latest.copyWith(
        isLoadingCompleted: false,
        actionError: failure.message,
      )),
      (items) => emit(latest.copyWith(
        isLoadingCompleted: false,
        completedItems: items,
      )),
    );
  }

  /// 입고 1회 → 성공하면 현재 탭의 목록을 재조회하고 stockRecorded 안내를 싣는다.
  Future<void> _onRecordPurchase(
    RecordPurchase event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(
      isRefreshing: true,
      clearActionError: true,
      clearStockRecorded: true,
    ));

    final result = await recordPurchaseUseCase(
      event.productId,
      event.sellerId,
      event.purchasedOn,
      event.quantity,
      totalAmount: event.totalAmount,
      unitPrice: event.unitPrice,
      reflectToBasePrice: event.reflectToBasePrice,
      // Always true — the server writes stock only while the stock link is on
      // (FEATURE_2610_09 D65).
      recordStock: true,
    );
    await result.fold(
      (failure) async => emit(current.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (recordResult) async => _refreshAfterAction(
        current,
        emit,
        stockRecorded: recordResult.stockRecorded,
      ),
    );
  }

  /// 입고 결과 안내를 소비했다 — 다음 리빌드에 다시 뜨지 않게 지운다.
  void _onClearStockNotice(
    ClearStockNotice event,
    Emitter<PurchaseListState> emit,
  ) {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.stockRecorded == null) return;

    emit(current.copyWith(clearStockRecorded: true));
  }

  Future<void> _onAdjustManualQty(
    AdjustManualQty event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(isRefreshing: true, clearActionError: true));

    final result = await adjustManualQtyUseCase(event.itemId, event.manualQty);
    await result.fold(
      (failure) async => emit(current.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (_) async => _refreshAfterAction(current, emit),
    );
  }

  Future<void> _onAddManualItem(
    AddManualItem event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(isRefreshing: true, clearActionError: true));

    final result = await addManualItemUseCase(
      event.productId,
      event.sellerId,
      event.quantity,
    );
    await result.fold(
      (failure) async => emit(current.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (_) async => _refreshAfterAction(current, emit),
    );
  }

  /// D5: the current tab reloads with the new filter, the other one is marked
  /// for reload on its next entry.
  Future<void> _onChangeSellerFilter(
    ChangeSellerFilter event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    final next = current.copyWith(
      filterSellerId: event.sellerId,
      clearFilterSeller: event.sellerId == null,
    );
    if (current.activeTab == PurchaseTab.completed) {
      await _loadCompleted(
        next.copyWith(listStale: true),
        current.completedFrom,
        current.completedTo,
        emit,
      );
      return;
    }
    await _reloadList(next.copyWith(clearCompleted: true), emit);
  }

  Future<void> _onCheckShare(
    CheckShare event,
    Emitter<PurchaseListState> emit,
  ) async {
    await _runAction(
      emit,
      () => checkPurchaseShareUseCase(
        event.productId,
        event.sellerId,
        event.status,
      ),
    );
  }

  Future<void> _onCancelShareCheck(
    CancelShareCheck event,
    Emitter<PurchaseListState> emit,
  ) async {
    await _runAction(
      emit,
      () => checkPurchaseShareUseCase.cancel(event.checkId),
    );
  }

  Future<void> _onChangeManualSeller(
    ChangeManualSeller event,
    Emitter<PurchaseListState> emit,
  ) async {
    await _runAction(
      emit,
      () => changeManualSellerUseCase(event.itemId, event.sellerId),
      movedManualItemId: event.itemId,
    );
  }

  Future<void> _onDeleteManualLine(
    DeleteManualLine event,
    Emitter<PurchaseListState> emit,
  ) async {
    await _runAction(
      emit,
      () => deleteManualItemUseCase(event.itemId),
      deletedManualItemId: event.itemId,
    );
  }

  /// Runs one write, then reloads the current tab; a failure keeps the list
  /// and travels as actionError. [deletedManualItemId] and [movedManualItemId]
  /// go into the state only on success; a success without [movedManualItemId]
  /// clears the last moved line (FEATURE_2610_09 D64).
  Future<void> _runAction(
    Emitter<PurchaseListState> emit,
    Future<Either<Failure, void>> Function() action, {
    int? deletedManualItemId,
    int? movedManualItemId,
  }) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(isRefreshing: true, clearActionError: true));

    final result = await action();
    await result.fold(
      (failure) async => emit(current.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (_) async => _refreshAfterAction(
        current.copyWith(
          deletedManualItemId: deletedManualItemId,
          movedManualItemId: movedManualItemId,
          clearMovedManualItem: movedManualItemId == null,
        ),
        emit,
      ),
    );
  }

  /// Reloads the list tab with [base]'s filter.
  Future<void> _reloadList(
    PurchaseListLoaded base,
    Emitter<PurchaseListState> emit,
  ) async {
    emit(base.copyWith(isRefreshing: true, clearActionError: true));
    final result =
        await getPurchaseListUseCase(sellerId: base.filterSellerId);
    result.fold(
      (failure) => emit(base.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (res) => emit(base.copyWith(
        isRefreshing: false,
        items: res.items,
        skippedToday: res.skippedToday,
        unmappedOrders: res.unmappedOrders,
      )),
    );
  }

  /// Reloads **the current tab** after a successful action.
  ///
  /// Completed tab: reloads the completed list with the applied range and
  /// filter (D21) and marks the list stale (FEATURE_2610_09 D5). List tab:
  /// reloads the list with the filter and drops the completed cache. A failed
  /// reload keeps the list and only carries actionError.
  Future<void> _refreshAfterAction(
    PurchaseListLoaded current,
    Emitter<PurchaseListState> emit, {
    bool? stockRecorded,
  }) async {
    if (current.activeTab == PurchaseTab.completed) {
      await _loadCompleted(
        current.copyWith(
          isRefreshing: false,
          stockRecorded: stockRecorded,
          listStale: true,
        ),
        current.completedFrom,
        current.completedTo,
        emit,
      );
      return;
    }

    final result =
        await getPurchaseListUseCase(sellerId: current.filterSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isRefreshing: false,
        clearCompleted: true,
        actionError: failure.message,
        stockRecorded: stockRecorded,
      )),
      (res) => emit(current.copyWith(
        isRefreshing: false,
        items: res.items,
        skippedToday: res.skippedToday,
        unmappedOrders: res.unmappedOrders,
        clearCompleted: true,
        stockRecorded: stockRecorded,
      )),
    );
  }
}
