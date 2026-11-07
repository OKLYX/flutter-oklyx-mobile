import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/get_stock_daily_usecase.dart';

/// 「일별 입출고 내역」 state (FEATURE_2610_19 D119 · FEATURE_2611_01 D14).
///
/// Events: [LoadStockDaily] (screen entry, date change, after a save — the
/// checks start empty), [ToggleStockDailyCheck] (one check of the shared
/// check column), [SelectStockDailyChip] and [ToggleStockDailyBox]
/// (FEATURE_2611_17 D4 · D28 — kept across loads, a change clears the checks).
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

/// The chip 「전체」/「입고」/「출고」 was picked (FEATURE_2611_17 D4).
class SelectStockDailyChip extends StockDailyEvent {
  final DailyChip chip;

  SelectStockDailyChip(this.chip);
}

/// The two check boxes next to the chip (FEATURE_2611_17 D24 · D29).
enum StockDailyBox { undecided, receiptPending }

/// One check box next to the chip was switched (FEATURE_2611_17 D28).
class ToggleStockDailyBox extends StockDailyEvent {
  final StockDailyBox box;

  ToggleStockDailyBox(this.box);
}

sealed class StockDailyState {}

class StockDailyLoading extends StockDailyState {}

class StockDailyLoaded extends StockDailyState {
  final StockDaily daily;

  /// Checked keys of the check column (D14).
  final Set<String> checked;

  /// The chip and the two boxes (FEATURE_2611_17 D4 · D28).
  final DailyChip chip;
  final bool undecidedBox;
  final bool receiptBox;

  StockDailyLoaded(
    this.daily, {
    this.checked = const {},
    this.chip = DailyChip.all,
    this.undecidedBox = false,
    this.receiptBox = false,
  });

  /// The rows the list shows under the chip and the boxes (D11).
  List<VisibleDailyRow> get visibleRows => visibleDailyRows(
        daily.rows,
        chip,
        undecidedBox: undecidedBox,
        receiptBox: receiptBox,
      );
}

class StockDailyError extends StockDailyState {
  final String message;

  StockDailyError(this.message);
}

class StockDailyBloc extends Bloc<StockDailyEvent, StockDailyState> {
  final GetStockDailyUseCase getStockDailyUseCase;

  // The chip and boxes stay through every load (FEATURE_2611_17 D4 · D28).
  DailyChip _chip = DailyChip.all;
  bool _undecidedBox = false;
  bool _receiptBox = false;

  StockDailyBloc({required this.getStockDailyUseCase})
      : super(StockDailyLoading()) {
    on<LoadStockDaily>((event, emit) async {
      emit(StockDailyLoading());
      final result = await getStockDailyUseCase(event.date);
      result.fold(
        (failure) => emit(StockDailyError(failure.message)),
        (daily) => emit(_loaded(daily)),
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
      emit(_loaded(current.daily, checked: checked));
    });
    on<SelectStockDailyChip>((event, emit) {
      _chip = event.chip;
      _emitFilter(emit);
    });
    on<ToggleStockDailyBox>((event, emit) {
      switch (event.box) {
        case StockDailyBox.undecided:
          _undecidedBox = !_undecidedBox;
        case StockDailyBox.receiptPending:
          _receiptBox = !_receiptBox;
      }
      _emitFilter(emit);
    });
  }

  StockDailyLoaded _loaded(StockDaily daily,
          {Set<String> checked = const {}}) =>
      StockDailyLoaded(
        daily,
        checked: checked,
        chip: _chip,
        undecidedBox: _undecidedBox,
        receiptBox: _receiptBox,
      );

  /// A chip or box change clears the checks (D4 · D28).
  void _emitFilter(Emitter<StockDailyState> emit) {
    final current = state;
    if (current is! StockDailyLoaded) {
      return;
    }
    emit(_loaded(current.daily));
  }
}
