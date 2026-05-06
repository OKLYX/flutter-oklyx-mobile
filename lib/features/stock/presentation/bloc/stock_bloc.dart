import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/create_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/get_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_event.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetStockUseCase getStockUseCase;
  final CreateStockUseCase createStockUseCase;

  StockBloc({
    required this.getStockUseCase,
    required this.createStockUseCase,
  }) : super(const StockInitial()) {
    on<GetStockRequested>(_onGetStock);
    on<CreateStockRequested>(_onCreateStock);
  }

  Future<void> _onGetStock(
    GetStockRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(const StockLoading());
    final result = await getStockUseCase(event.barcodeId);
    result.fold(
      (failure) => emit(StockError(failure.message)),
      (response) => emit(
        StockLoaded(
          inStock: response.inStock,
          barcodeId: response.barcodeId,
        ),
      ),
    );
  }

  Future<void> _onCreateStock(
    CreateStockRequested event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StockLoaded && currentState is! StockSubmitError) {
      return;
    }

    final inStock = currentState is StockLoaded
        ? currentState.inStock
        : (currentState as StockSubmitError).inStock;
    final barcodeId = currentState is StockLoaded
        ? currentState.barcodeId
        : (currentState as StockSubmitError).barcodeId;

    emit(StockSubmitting(inStock: inStock, barcodeId: barcodeId));

    final result = await createStockUseCase(event.request);

    result.fold(
      (failure) {
        emit(
          StockSubmitError(
            message: failure.message,
            inStock: inStock,
            barcodeId: barcodeId,
          ),
        );
      },
      (response) {
        emit(
          StockSubmitSuccess(
            inStock: response.inStock,
            barcodeId: response.barcodeId,
          ),
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          emit(
            StockLoaded(
              inStock: response.inStock,
              barcodeId: response.barcodeId,
            ),
          );
        });
      },
    );
  }
}
