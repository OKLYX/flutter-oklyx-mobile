import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_item_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/create_batch_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/get_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/models/stock_in_out_item.dart';

import 'stock_in_out_event.dart';
import 'stock_in_out_state.dart';

class StockInOutBloc extends Bloc<StockInOutEvent, StockInOutState> {
  final GetStockUseCase getStockUseCase;
  final CreateBatchStockUseCase createBatchStockUseCase;

  StockInOutBloc({
    required this.getStockUseCase,
    required this.createBatchStockUseCase,
  }) : super(const StockInOutInitial()) {
    on<StockTypeChanged>(_onStockTypeChanged);
    on<BarcodeSearched>(_onBarcodeSearched);
    on<QuantityUpdated>(_onQuantityUpdated);
    on<ItemRemoved>(_onItemRemoved);
    on<BatchSubmitRequested>(_onBatchSubmitRequested);
  }

  Future<void> _onStockTypeChanged(
    StockTypeChanged event,
    Emitter<StockInOutState> emit,
  ) async {
    emit(StockInOutLoaded([], event.type));
  }

  Future<void> _onBarcodeSearched(
    BarcodeSearched event,
    Emitter<StockInOutState> emit,
  ) async {
    final currentState = state;
    final selectedType = currentState is StockInOutLoaded
        ? currentState.selectedType
        : StockType.IN;
    final items = currentState is StockInOutLoaded
        ? List<StockInOutItem>.from(currentState.items)
        : <StockInOutItem>[];

    emit(const BarcodeSearchLoading());

    final result = await getStockUseCase(event.barcode);

    result.fold(
      (failure) {
        emit(BarcodeSearchError(failure.message));
        emit(StockInOutLoaded(items, selectedType));
      },
      (stock) {
        final existingItemIndex =
            items.indexWhere((item) => item.barcodeId == event.barcode);

        bool hasExceeded = false;
        if (existingItemIndex >= 0) {
          final newQuantity = items[existingItemIndex].quantity + 1;
          if (selectedType == StockType.OUT && newQuantity > stock.inStock) {
            hasExceeded = true;
            items[existingItemIndex].quantity = stock.inStock;
          } else {
            items[existingItemIndex].quantity = newQuantity;
          }
        } else {
          items.add(
            StockInOutItem(
              barcodeId: event.barcode,
              name: stock.productName,
              currentStock: stock.inStock,
              quantity: 1,
            ),
          );
        }

        if (hasExceeded) {
          emit(const QuantityExceededAlert('출고 가능 수량을 초과하였습니다.'));
        }

        emit(StockInOutLoaded(items, selectedType));
      },
    );
  }

  Future<void> _onQuantityUpdated(
    QuantityUpdated event,
    Emitter<StockInOutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StockInOutLoaded) return;

    final items = List<StockInOutItem>.from(currentState.items);
    if (event.index >= 0 && event.index < items.length) {
      int quantity = event.newQuantity;
      final item = items[event.index];

      if (currentState.selectedType == StockType.OUT) {
        quantity = quantity > item.currentStock
            ? item.currentStock
            : quantity;
      }

      quantity = quantity < 1 ? 1 : quantity;
      item.quantity = quantity;
    }

    emit(StockInOutLoaded(items, currentState.selectedType));
  }

  Future<void> _onItemRemoved(
    ItemRemoved event,
    Emitter<StockInOutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StockInOutLoaded) return;

    final items = List<StockInOutItem>.from(currentState.items);
    if (event.index >= 0 && event.index < items.length) {
      items.removeAt(event.index);
    }

    emit(StockInOutLoaded(items, currentState.selectedType));
  }

  Future<void> _onBatchSubmitRequested(
    BatchSubmitRequested event,
    Emitter<StockInOutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StockInOutLoaded || currentState.items.isEmpty) {
      emit(const StockInOutSubmitError('추가된 제품이 없습니다'));
      return;
    }

    emit(const StockInOutSubmitting());

    final batchItems = currentState.items
        .map((item) => BatchStockItemEntity(
          barcodeId: item.barcodeId,
          quantity: item.quantity,
          name: item.name,
        ))
        .toList();

    final batchRequest = BatchStockRequestEntity(
      type: currentState.selectedType,
      items: batchItems,
    );

    final result = await createBatchStockUseCase(batchRequest);

    result.fold(
      (failure) {
        emit(StockInOutSubmitError(failure.message));
        emit(StockInOutLoaded(currentState.items, currentState.selectedType));
      },
      (response) {
        emit(const StockInOutSubmitSuccess());
        Future.delayed(const Duration(seconds: 2), () {
          add(StockTypeChanged(currentState.selectedType));
        });
      },
    );
  }
}
