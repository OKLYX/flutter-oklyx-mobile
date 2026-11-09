import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/get_stock_daily_usecase.dart';

/// 「일별 입출고 내역」 state (FEATURE_2610_19 D119 · FEATURE_2611_01 D14).
///
/// Events: [LoadStockDaily] (screen entry, date change, after a save — the
/// checks start empty), [ToggleStockDailyCheck] (one check of the shared
/// check column), [SelectStockDailyChip] and [ToggleStockDailyBox]
/// (FEATURE_2611_17 D4 · D28 — kept across loads, a change clears the checks),
/// [GoToStockDailyRow] (FEATURE_2611_21 D19 — 「입고로 이동」, resets the chip
/// and the boxes).
/// States: [StockDailyLoading] → [StockDailyLoaded] or [StockDailyError].
/// [StockDailyBloc.day] = the day loaded last (the screen day).
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

/// 「○월 ○일 입고로 이동」 (FEATURE_2611_21 D19): every row shows (chip
/// 「전체」, boxes off), [date] loads, then the lot [movementId] gets its row
/// sheet ([StockDailyLoaded.focusId]) or a highlight for
/// [StockDailyBloc.highlightDuration] when it has none.
class GoToStockDailyRow extends StockDailyEvent {
  final String date;
  final int movementId;

  GoToStockDailyRow(this.date, this.movementId);
}

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

  /// FEATURE_2611_21 D19: the lot whose row sheet the page opens now (one
  /// state only) · the lot highlighted without a row sheet.
  final int? focusId;
  final int? highlightId;

  StockDailyLoaded(
    this.daily, {
    this.checked = const {},
    this.chip = DailyChip.all,
    this.undecidedBox = false,
    this.receiptBox = false,
    this.focusId,
    this.highlightId,
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

  /// How long a lot without a row sheet stays highlighted (D19).
  static const Duration highlightDuration = Duration(seconds: 2);

  String _day = '';

  /// The day loaded last (yyyy-MM-dd) — the screen day.
  String get day => _day;

  // The chip and boxes stay through every load (FEATURE_2611_17 D4 · D28) —
  // [GoToStockDailyRow] resets them (FEATURE_2611_21 D19).
  DailyChip _chip = DailyChip.all;
  bool _undecidedBox = false;
  bool _receiptBox = false;

  StockDailyBloc({required this.getStockDailyUseCase})
      : super(StockDailyLoading()) {
    on<LoadStockDaily>((event, emit) async {
      _day = event.date;
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
    on<GoToStockDailyRow>((event, emit) async {
      _chip = DailyChip.all;
      _undecidedBox = false;
      _receiptBox = false;
      _day = event.date;
      emit(StockDailyLoading());
      final result = await getStockDailyUseCase(event.date);
      final daily = result.fold<StockDaily?>((failure) {
        emit(StockDailyError(failure.message));
        return null;
      }, (daily) => daily);
      if (daily == null) {
        return;
      }
      StockDailyRow? arrived;
      for (final row in daily.rows) {
        if (row.movementId == event.movementId) {
          arrived = row;
        }
      }
      if (arrived == null) {
        emit(_loaded(daily));
        return;
      }
      if (arrived.editTarget != null) {
        emit(_loaded(daily, focusId: event.movementId));
        return;
      }
      emit(_loaded(daily, highlightId: event.movementId));
      await Future<void>.delayed(highlightDuration);
      final current = state;
      if (current is StockDailyLoaded &&
          current.highlightId == event.movementId) {
        emit(_loaded(current.daily, checked: current.checked));
      }
    });
  }

  StockDailyLoaded _loaded(
    StockDaily daily, {
    Set<String> checked = const {},
    int? focusId,
    int? highlightId,
  }) =>
      StockDailyLoaded(
        daily,
        checked: checked,
        chip: _chip,
        undecidedBox: _undecidedBox,
        receiptBox: _receiptBox,
        focusId: focusId,
        highlightId: highlightId,
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
