import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/get_stock_daily_usecase.dart';

/// 「일별 입출고 내역」 state (FEATURE_2610_19 D119 · FEATURE_2611_01 D14).
///
/// Events: [LoadStockDaily] (screen entry, date change, after a save — the
/// checks start empty) and [ToggleStockDailyCheck] (one check of the shared
/// check column).
/// States: [StockDailyLoading] → [StockDailyLoaded] or [StockDailyError].
sealed class StockDailyEvent {}

class LoadStockDaily extends StockDailyEvent {
  final String date;

  LoadStockDaily(this.date);
}

/// [key] = `row-{movementId}` or `share-{recordId}`.
class ToggleStockDailyCheck extends StockDailyEvent {
  final String key;

  ToggleStockDailyCheck(this.key);
}

sealed class StockDailyState {}

class StockDailyLoading extends StockDailyState {}

class StockDailyLoaded extends StockDailyState {
  final StockDaily daily;

  /// Checked keys of the check column (D14).
  final Set<String> checked;

  StockDailyLoaded(this.daily, {this.checked = const {}});
}

class StockDailyError extends StockDailyState {
  final String message;

  StockDailyError(this.message);
}

class StockDailyBloc extends Bloc<StockDailyEvent, StockDailyState> {
  final GetStockDailyUseCase getStockDailyUseCase;

  StockDailyBloc({required this.getStockDailyUseCase})
      : super(StockDailyLoading()) {
    on<LoadStockDaily>((event, emit) async {
      emit(StockDailyLoading());
      final result = await getStockDailyUseCase(event.date);
      result.fold(
        (failure) => emit(StockDailyError(failure.message)),
        (daily) => emit(StockDailyLoaded(daily)),
      );
    });
    on<ToggleStockDailyCheck>((event, emit) {
      final current = state;
      if (current is! StockDailyLoaded) {
        return;
      }
      final checked = Set<String>.of(current.checked);
      if (!checked.remove(event.key)) {
        checked.add(event.key);
      }
      emit(StockDailyLoaded(current.daily, checked: checked));
    });
  }
}
