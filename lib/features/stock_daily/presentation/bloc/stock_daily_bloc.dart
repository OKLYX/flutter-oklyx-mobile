import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/get_stock_daily_usecase.dart';

/// 「그날 입출고 내역」 state (FEATURE_2610_19 D119).
///
/// One event: [LoadStockDaily] (screen entry, date change, after an
/// assignment).
/// States: [StockDailyLoading] → [StockDailyLoaded] or [StockDailyError].
sealed class StockDailyEvent {}

class LoadStockDaily extends StockDailyEvent {
  final String date;

  LoadStockDaily(this.date);
}

sealed class StockDailyState {}

class StockDailyLoading extends StockDailyState {}

class StockDailyLoaded extends StockDailyState {
  final StockDaily daily;

  StockDailyLoaded(this.daily);
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
  }
}
