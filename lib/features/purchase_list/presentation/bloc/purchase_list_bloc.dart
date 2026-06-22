import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/usecases/adjust_manual_qty_usecase.dart';
import '../../domain/usecases/extract_purchase_list_usecase.dart';
import '../../domain/usecases/get_purchase_list_usecase.dart';
import '../../domain/usecases/record_purchase_usecase.dart';
import 'purchase_list_event.dart';
import 'purchase_list_state.dart';

/// 구매목록 BLoC
///
/// 프론트 PurchaseListContainer와 동일하게 동작한다:
/// - 진입 시 판매자 목록 + 전체 구매목록 로드 ([LoadPurchaseList])
/// - 판매자 선택 ([SelectSeller]) 시 즉시 재조회 (웹과 동일, 별도 조회 버튼 없음)
/// - 재적재 ([ExtractPurchaseList]) 후 목록 갱신 (수동수량/구매기록 유지)
/// - 상품 카드 펼침 토글 ([ToggleExpand])
/// - 라인 구매기록 ([RecordPurchase]) / 수동수량 교체 ([AdjustManualQty]) 후 재조회
///
/// 판매자 목록은 기존 seller 기능의 [GetSellersUseCase]를 재사용한다.
class PurchaseListBloc extends Bloc<PurchaseListEvent, PurchaseListState> {
  final GetPurchaseListUseCase getPurchaseListUseCase;
  final ExtractPurchaseListUseCase extractPurchaseListUseCase;
  final RecordPurchaseUseCase recordPurchaseUseCase;
  final AdjustManualQtyUseCase adjustManualQtyUseCase;
  final GetSellersUseCase getSellersUseCase;

  PurchaseListBloc({
    required this.getPurchaseListUseCase,
    required this.extractPurchaseListUseCase,
    required this.recordPurchaseUseCase,
    required this.adjustManualQtyUseCase,
    required this.getSellersUseCase,
  }) : super(PurchaseListInitial()) {
    on<LoadPurchaseList>(_onLoad);
    on<SelectSeller>(_onSelectSeller);
    on<ExtractPurchaseList>(_onExtract);
    on<ToggleExpand>(_onToggleExpand);
    on<RecordPurchase>(_onRecordPurchase);
    on<AdjustManualQty>(_onAdjustManualQty);
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
      (items) => emit(PurchaseListLoaded(sellers: sellers, items: items)),
    );
  }

  /// 판매자 선택 → 즉시 재조회 (펼침 상태는 초기화).
  Future<void> _onSelectSeller(
    SelectSeller event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.isRefreshing || current.isExtracting) return;

    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
      clearExpanded: true,
      isRefreshing: true,
      clearActionError: true,
    ));

    final result = await getPurchaseListUseCase(event.sellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        selectedSellerId: event.sellerId,
        clearSelectedSeller: event.sellerId == null,
        isRefreshing: false,
        actionError: failure.message,
      )),
      (items) => emit(current.copyWith(
        selectedSellerId: event.sellerId,
        clearSelectedSeller: event.sellerId == null,
        clearExpanded: true,
        items: items,
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
    if (current.isRefreshing || current.isExtracting) return;

    emit(current.copyWith(isExtracting: true, clearActionError: true));

    final result = await extractPurchaseListUseCase(current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isExtracting: false,
        actionError: failure.message,
      )),
      (items) => emit(current.copyWith(
        isExtracting: false,
        items: items,
        clearExpanded: true,
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

  Future<void> _onRecordPurchase(
    RecordPurchase event,
    Emitter<PurchaseListState> emit,
  ) async {
    final current = state;
    if (current is! PurchaseListLoaded) return;
    if (current.isRefreshing || current.isExtracting) return;

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
    if (current.isRefreshing || current.isExtracting) return;

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

  /// 라인 액션(구매기록/수동조정) 성공 후 현재 판매자 기준으로 목록 재조회.
  /// 재조회 실패는 목록을 유지한 채 actionError만 전달한다.
  Future<void> _refreshAfterAction(
    PurchaseListLoaded current,
    Emitter<PurchaseListState> emit,
  ) async {
    final result = await getPurchaseListUseCase(current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isRefreshing: false,
        actionError: failure.message,
      )),
      (items) => emit(current.copyWith(isRefreshing: false, items: items)),
    );
  }
}
