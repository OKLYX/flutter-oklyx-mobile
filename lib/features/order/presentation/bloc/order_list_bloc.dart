import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_list_event.dart';
import 'order_list_state.dart';

/// 주문내역 조회/동기화 BLoC
///
/// 프론트 OrderContainer와 동일하게 동작한다:
/// - 진입 시 판매자 목록 + 전체 주문 로드 ([LoadOrders])
/// - 판매자 선택 ([SelectSeller]) 후 조회 ([SearchOrders])
/// - 외부 마켓플레이스 동기화 ([SyncOrders]) 후 목록 갱신 + 결과 요약 표시
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
    on<SelectStatus>(_onSelectStatus);
  }

  Future<void> _onLoad(LoadOrders event, Emitter<OrderListState> emit) async {
    emit(OrderListLoading());

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백 (프론트와 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    final ordersResult = await orderUseCase.getOrders();
    ordersResult.fold(
      (failure) => emit(OrderListError(message: failure.message)),
      (orders) => emit(OrderListLoaded(sellers: sellers, orders: orders)),
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

  Future<void> _onSearch(
    SearchOrders event,
    Emitter<OrderListState> emit,
  ) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing) return;

    emit(current.copyWith(isSearching: true, clearActionError: true, clearSyncResult: true));

    final result = await orderUseCase.getOrders(sellerId: current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isSearching: false,
        orders: const [],
        actionError: failure.message,
      )),
      (orders) => emit(current.copyWith(isSearching: false, orders: orders)),
    );
  }

  Future<void> _onSync(SyncOrders event, Emitter<OrderListState> emit) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing) return;

    emit(current.copyWith(isSyncing: true, clearActionError: true, clearSyncResult: true));

    final result = await orderUseCase.syncOrders(sellerId: current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isSyncing: false,
        actionError: failure.message,
      )),
      (sync) => emit(current.copyWith(
        isSyncing: false,
        orders: sync.orders,
        syncResult: sync,
        lastSyncedAt: sync.syncedAt,
      )),
    );
  }
}
