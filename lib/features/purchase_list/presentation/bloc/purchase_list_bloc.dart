import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/usecases/add_manual_item_usecase.dart';
import '../../domain/usecases/adjust_manual_qty_usecase.dart';
import '../../domain/usecases/extract_purchase_list_usecase.dart';
import '../../domain/usecases/get_completed_purchase_list_usecase.dart';
import '../../domain/usecases/get_purchase_list_usecase.dart';
import '../../domain/usecases/record_purchase_usecase.dart';
import 'purchase_list_event.dart';
import 'purchase_list_state.dart';

/// 구매목록 BLoC (PLAN 2609_29)
///
/// - 진입 시 판매자 목록 + 구매목록(+미매핑주문) 로드 ([LoadPurchaseList])
/// - 주문내역 동기화 ([SyncOrders]) = 동기화 + 재적재 한 번에 (별도 [재적재] 없음, D12)
/// - 탭 전환 ([SwitchTab]) — 완료내역은 지연 로드 후 캐시
/// - 상품 카드 펼침 토글 (active: [ToggleExpand], completed: [ToggleExpandCompleted])
/// - 입고 ([RecordPurchase]) / 수동수량 교체 ([AdjustManualQty]) /
///   수동항목 추가 ([AddManualItem]) 후 재조회
///
/// 🔴 판매자 스코프가 없다(D11) — 조회·동기화는 항상 전체이고, 판매자는 입고 요청의
/// 귀속 값으로만 등장한다. 판매자 목록은 입고 카드 드롭다운이 쓴다.
/// 🔴 최근 구매이력은 이 BLoC 에 담지 않는다(D9) — 그룹마다 상태가 N벌이라 목록 상태와
/// 뒤엉킨다. 입고 카드 위젯이 `GetRecentPurchasesUseCase` 를 직접 호출해 로컬로 들고 있다.
///
/// 판매자 목록은 seller 기능의 [GetSellersUseCase], 주문동기화는 order 기능의
/// [OrderUseCase]를 재사용한다.
class PurchaseListBloc extends Bloc<PurchaseListEvent, PurchaseListState> {
  final GetPurchaseListUseCase getPurchaseListUseCase;
  final ExtractPurchaseListUseCase extractPurchaseListUseCase;
  final GetCompletedPurchaseListUseCase getCompletedPurchaseListUseCase;
  final RecordPurchaseUseCase recordPurchaseUseCase;
  final AdjustManualQtyUseCase adjustManualQtyUseCase;
  final AddManualItemUseCase addManualItemUseCase;
  final GetSellersUseCase getSellersUseCase;
  final OrderUseCase orderUseCase;

  PurchaseListBloc({
    required this.getPurchaseListUseCase,
    required this.extractPurchaseListUseCase,
    required this.getCompletedPurchaseListUseCase,
    required this.recordPurchaseUseCase,
    required this.adjustManualQtyUseCase,
    required this.addManualItemUseCase,
    required this.getSellersUseCase,
    required this.orderUseCase,
  }) : super(PurchaseListInitial()) {
    on<LoadPurchaseList>(_onLoad);
    on<SyncOrders>(_onSync);
    on<SwitchTab>(_onSwitchTab);
    on<ToggleExpand>(_onToggleExpand);
    on<ToggleExpandCompleted>(_onToggleExpandCompleted);
    on<ApplyCompletedFilter>(_onApplyCompletedFilter);
    on<ResetCompletedFilter>(_onResetCompletedFilter);
    on<RecordPurchase>(_onRecordPurchase);
    on<ClearStockNotice>(_onClearStockNotice);
    on<AdjustManualQty>(_onAdjustManualQty);
    on<AddManualItem>(_onAddManualItem);
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

    final listResult = await getPurchaseListUseCase();
    listResult.fold(
      (failure) => emit(PurchaseListError(message: failure.message)),
      (result) => emit(PurchaseListLoaded(
        sellers: sellers,
        items: result.items,
        unmappedOrders: result.unmappedOrders,
        completedFrom: _todayStr(),
        completedTo: _todayStr(),
      )),
    );
  }

  /// 주문내역 동기화: order 기능 동기화 후 재적재해 구매목록을 갱신한다.
  /// 동기화 범위는 항상 전체다(D11).
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
        extracted.fold(
          (failure) => emit(current.copyWith(
            isSyncing: false,
            syncResult: sync,
            actionError: failure.message,
          )),
          (res) => emit(current.copyWith(
            isSyncing: false,
            syncResult: sync,
            items: res.items,
            unmappedOrders: res.unmappedOrders,
            clearExpanded: true,
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

  /// 완료내역 필터 초기화 → 구매일 오늘로 재조회.
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

  /// 완료내역을 주어진 구매일 기간으로 조회한다. 필터 값은 상태에 함께 저장해
  /// active 탭 변이 후 완료 탭 재진입 시에도 유지한다.
  Future<void> _loadCompleted(
    PurchaseListLoaded base,
    String from,
    String to,
    Emitter<PurchaseListState> emit, {
    bool keepExpanded = false,
  }) async {
    emit(base.copyWith(
      completedFrom: from,
      completedTo: to,
      clearExpandedCompleted: !keepExpanded,
      isLoadingCompleted: true,
      clearActionError: true,
    ));

    final result = await getCompletedPurchaseListUseCase(
      from.isEmpty ? null : from,
      to.isEmpty ? null : to,
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

  void _onToggleExpand(ToggleExpand event, Emitter<PurchaseListState> emit) {
    final current = state;
    if (current is! PurchaseListLoaded) return;

    final isOpen = current.expandedProductId == event.productId;
    emit(current.copyWith(
      expandedProductId: isOpen ? null : event.productId,
      clearExpanded: isOpen,
    ));
  }

  void _onToggleExpandCompleted(
    ToggleExpandCompleted event,
    Emitter<PurchaseListState> emit,
  ) {
    final current = state;
    if (current is! PurchaseListLoaded) return;

    final isOpen = current.expandedCompletedProductId == event.productId;
    emit(current.copyWith(
      expandedCompletedProductId: isOpen ? null : event.productId,
      clearExpandedCompleted: isOpen,
    ));
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
      // D19 — 화면 체크박스는 체크 + 비활성이라 항상 즉시 반영이다.
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

    final result = await addManualItemUseCase(event.productId, event.quantity);
    await result.fold(
      (failure) async => emit(current.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (_) async => _refreshAfterAction(current, emit),
    );
  }

  /// 액션 성공 후 **현재 탭의** 목록을 재조회한다.
  ///
  /// 완료 탭이면 화면에 적용 중인 기간(from/to)을 유지한 채 완료 목록을 다시 부른다
  /// (D21) — 구매목록 조회로 갈아타지 않는다. 구매목록 탭이면 완료 캐시를 무효화해
  /// 완료 탭 재진입 시 최신을 받는다. 재조회 실패는 목록을 유지한 채 actionError 만 전달한다.
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
        ),
        current.completedFrom,
        current.completedTo,
        emit,
        keepExpanded: true,
      );
      return;
    }

    final result = await getPurchaseListUseCase();
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
        unmappedOrders: res.unmappedOrders,
        clearCompleted: true,
        stockRecorded: stockRecorded,
      )),
    );
  }
}
