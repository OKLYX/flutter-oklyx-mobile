import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/get_stock_logs_usecase.dart';

import 'stock_search_event.dart';
import 'stock_search_state.dart';

class StockSearchBloc extends Bloc<StockSearchEvent, StockSearchState> {
  final GetStockLogsUseCase getStockLogsUseCase;

  GetStockLogsParamsEntity? _lastSearchParams;

  StockSearchBloc({
    required this.getStockLogsUseCase,
  }) : super(const StockSearchInitial()) {
    on<StockSearchRequested>(_onStockSearchRequested);
    on<StockSearchPageChanged>(_onStockSearchPageChanged);
  }

  Future<void> _onStockSearchRequested(
    StockSearchRequested event,
    Emitter<StockSearchState> emit,
  ) async {
    emit(const StockSearchLoading());

    _lastSearchParams = event.params;

    final result = await getStockLogsUseCase(event.params);

    result.fold(
      (failure) {
        emit(StockSearchError(failure.message));
      },
      (response) {
        emit(StockSearchLoaded(
          logs: response.content,
          currentPage: response.page,
          totalElements: response.totalElements,
          totalPages: response.totalPages,
        ));
      },
    );
  }

  Future<void> _onStockSearchPageChanged(
    StockSearchPageChanged event,
    Emitter<StockSearchState> emit,
  ) async {
    if (_lastSearchParams == null) return;

    emit(const StockSearchLoading());

    final updatedParams = _lastSearchParams!.copyWith(page: event.newPage);
    _lastSearchParams = updatedParams;

    final result = await getStockLogsUseCase(updatedParams);

    result.fold(
      (failure) {
        emit(StockSearchError(failure.message));
      },
      (response) {
        emit(StockSearchLoaded(
          logs: response.content,
          currentPage: response.page,
          totalElements: response.totalElements,
          totalPages: response.totalPages,
        ));
      },
    );
  }
}
