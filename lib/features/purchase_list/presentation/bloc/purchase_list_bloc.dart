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

/// 구매목록 BLoC
///
/// 프론트 PurchaseListContainer와 동일하게 동작한다:
/// - 진입 시 판매자 목록 + 전체 구매목록(+미매핑주문) 로드 ([LoadPurchaseList])
/// - 판매자 선택 ([SelectSeller]) 시 즉시 재조회 (웹과 동일, 별도 조회 버튼 없음)
/// - 재적재 ([ExtractPurchaseList]) / 주문동기화 ([SyncOrders]) 후 목록 갱신
/// - 탭 전환 ([SwitchTab]) — 완료내역은 지연 로드 후 캐시
/// - 상품 카드 펼침 토글 (active: [ToggleExpand], completed: [ToggleExpandCompleted])
/// - 라인 구매기록 ([RecordPurchase]) / 수동수량 교체 ([AdjustManualQty]) /
///   수동항목 추가 ([AddManualItem]) 후 재조회
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
    on<SelectSeller>(_onSelectSeller);
    on<ExtractPurchaseList>(_onExtract);
    on<SyncOrders>(_onSync);
    on<SwitchTab>(_onSwitchTab);
    on<ToggleExpand>(_onToggleExpand);
    on<ToggleExpandCompleted>(_onToggleExpandCompleted);
    on<ApplyCompletedFilter>(_onApplyCompletedFilter);
    on<ResetCompletedFilter>(_onResetCompletedFilter);
    on<RecordPurchase>(_onRecordPurchase);
    on<AdjustManualQty>(_onAdjustManualQty);
    on<AddManualItem>(_onAddManualItem);
  }

  bool _busy(PurchaseListLoaded s) =>
      s.isRefreshing || s.isExtracting || s.isSyncing;

  /// 로컬 타임존 기준 오늘(YYYY-MM-DD). 완료내역 필터 기본값으로 사용한다(프론트와 동일).
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

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백 (프론트와 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    final listResult = await getPurchaseListUseCase(null);
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

  /// 판매자 선택 → 즉시 재조회 (펼침/동기화배너/완료캐시 초기화).
  Future<void> _onSelectSeller(
    SelectSeller event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
      clearExpanded: true,
      clearCompleted: true,
      clearSyncResult: true,
      isRefreshing: true,
      clearActionError: true,
    ));

    final result = await getPurchaseListUseCase(event.sellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        selectedSellerId: event.sellerId,
        clearSelectedSeller: event.sellerId == null,
        clearCompleted: true,
        isRefreshing: false,
        actionError: failure.message,
      )),
      (res) => emit(current.copyWith(
        selectedSellerId: event.sellerId,
        clearSelectedSeller: event.sellerId == null,
        clearExpanded: true,
        clearCompleted: true,
        clearSyncResult: true,
        items: res.items,
        unmappedOrders: res.unmappedOrders,
        isRefreshing: false,
      )),
    );
  }

  Future<void> _onExtract(
    ExtractPurchaseList event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(
      isExtracting: true,
      clearActionError: true,
      clearSyncResult: true,
    ));

    final result = await extractPurchaseListUseCase(current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isExtracting: false,
        actionError: failure.message,
      )),
      (res) => emit(current.copyWith(
        isExtracting: false,
        items: res.items,
        unmappedOrders: res.unmappedOrders,
        clearExpanded: true,
        clearCompleted: true,
      )),
    );
  }

  /// 주문동기화: order 기능 동기화 후 재적재해 구매목록을 갱신한다(웹과 동일).
  Future<void> _onSync(SyncOrders event, Emitter<PurchaseListState> emit) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(
      isSyncing: true,
      clearActionError: true,
      clearSyncResult: true,
    ));

    final syncResult = await orderUseCase.syncOrders(
      sellerId: current.selectedSellerId,
    );
    await syncResult.fold(
      (failure) async => emit(current.copyWith(
        isSyncing: false,
        actionError: failure.message,
      )),
      (sync) async {
        final extracted =
            await extractPurchaseListUseCase(current.selectedSellerId);
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
        current.completedSellerId,
        current.completedFrom,
        current.completedTo,
        emit,
      );
    }
  }

  /// 완료내역 필터 적용 → 해당 조건으로 재조회 (펼침 초기화).
  Future<void> _onApplyCompletedFilter(
    ApplyCompletedFilter event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.isLoadingCompleted) return;

    await _loadCompleted(current, event.sellerId, event.from, event.to, emit);
  }

  /// 완료내역 필터 초기화 → 판매자 전체 + 구매일 오늘로 재조회.
  Future<void> _onResetCompletedFilter(
    ResetCompletedFilter event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.isLoadingCompleted) return;

    final today = _todayStr();
    await _loadCompleted(current, null, today, today, emit);
  }

  /// 완료내역을 주어진 필터(판매자 + 구매일 기간)로 조회한다. 필터 값은 상태에
  /// 함께 저장해 active 탭 변이 후 완료 탭 재진입 시에도 유지한다.
  Future<void> _loadCompleted(
    PurchaseListLoaded base,
    int? sellerId,
    String from,
    String to,
    Emitter<PurchaseListState> emit,
  ) async {
    emit(base.copyWith(
      completedSellerId: sellerId,
      clearCompletedSeller: sellerId == null,
      completedFrom: from,
      completedTo: to,
      clearExpandedCompleted: true,
      isLoadingCompleted: true,
      clearActionError: true,
    ));

    final result = await getCompletedPurchaseListUseCase(
      sellerId,
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

  Future<void> _onRecordPurchase(
    RecordPurchase event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (_busy(current)) return;

    emit(current.copyWith(isRefreshing: true, clearActionError: true));

    final result = await recordPurchaseUseCase(
      event.itemId,
      event.purchasedOn,
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

  /// 라인 액션 성공 후 현재 판매자 기준으로 active 목록 재조회.
  /// 완료 캐시는 무효화해 완료 탭 재진입 시 최신 반영한다.
  /// 재조회 실패는 목록을 유지한 채 actionError만 전달한다.
  Future<void> _refreshAfterAction(
    PurchaseListLoaded current,
    Emitter<PurchaseListState> emit,
  ) async {
    final result = await getPurchaseListUseCase(current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isRefreshing: false,
        clearCompleted: true,
        actionError: failure.message,
      )),
      (res) => emit(current.copyWith(
        isRefreshing: false,
        items: res.items,
        unmappedOrders: res.unmappedOrders,
        clearCompleted: true,
      )),
    );
  }
}
