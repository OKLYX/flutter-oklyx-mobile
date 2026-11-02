import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/packing_history.dart';
import '../../domain/usecases/get_packing_history_usecase.dart';

/// 「포장 이력」 state (FEATURE_2611_03 / PLAN D29 · D31 · D34).
///
/// Event: [LoadPackingHistory] (screen entry, period chip, search submit,
/// retry). States: [PackingHistoryLoading] → [PackingHistoryLoaded] or
/// [PackingHistoryError]; each keeps the current `days`.
sealed class PackingHistoryEvent {}

/// [days] = 1 · 7 · 30, today included.
class LoadPackingHistory extends PackingHistoryEvent {
  final int days;
  final String keyword;

  LoadPackingHistory({required this.days, required this.keyword});
}

sealed class PackingHistoryState {
  final int days;

  PackingHistoryState(this.days);
}

class PackingHistoryLoading extends PackingHistoryState {
  PackingHistoryLoading(super.days);
}

class PackingHistoryLoaded extends PackingHistoryState {
  /// Rows in the server order.
  final List<PackingHistoryEntry> entries;

  PackingHistoryLoaded(super.days, this.entries);
}

class PackingHistoryError extends PackingHistoryState {
  final String message;

  PackingHistoryError(super.days, this.message);
}

class PackingHistoryBloc
    extends Bloc<PackingHistoryEvent, PackingHistoryState> {
  final GetPackingHistoryUseCase getPackingHistoryUseCase;

  PackingHistoryBloc({required this.getPackingHistoryUseCase})
      : super(PackingHistoryLoading(1)) {
    on<LoadPackingHistory>((event, emit) async {
      emit(PackingHistoryLoading(event.days));
      final format = DateFormat('yyyy-MM-dd');
      final today = DateTime.now();
      final from =
          DateTime(today.year, today.month, today.day - (event.days - 1));
      final result = await getPackingHistoryUseCase(
        format.format(from),
        format.format(today),
        event.keyword,
      );
      result.fold(
        (failure) => emit(PackingHistoryError(event.days, failure.message)),
        (entries) => emit(PackingHistoryLoaded(event.days, entries)),
      );
    });
  }
}
