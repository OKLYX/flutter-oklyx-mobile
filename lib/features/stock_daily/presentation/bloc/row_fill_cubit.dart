import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/entities/stock_fill.dart';
import '../../domain/usecases/fill_outbound_usecase.dart';
import '../../domain/usecases/get_fill_lots_usecase.dart';

/// State of the [입고로 채우기] sheet (FEATURE_2611_22 D3 ② · D15).
class RowFillState {
  /// The lots offered; null = loading.
  final List<FillLot>? lots;

  /// The picked lot; null = none.
  final int? lotId;

  /// 「개수」 as typed.
  final String quantity;

  final bool busy;

  /// Error text inside the sheet, blank when none.
  final String error;

  /// The sheet is done — it closes.
  final bool saved;

  const RowFillState({
    this.lots,
    this.lotId,
    this.quantity = '',
    this.busy = false,
    this.error = '',
    this.saved = false,
  });

  RowFillState copyWith({
    List<FillLot>? lots,
    int? lotId,
    String? quantity,
    bool? busy,
    String? error,
    bool? saved,
  }) =>
      RowFillState(
        lots: lots ?? this.lots,
        lotId: lotId ?? this.lotId,
        quantity: quantity ?? this.quantity,
        busy: busy ?? this.busy,
        error: error ?? this.error,
        saved: saved ?? this.saved,
      );
}

/// Cubit of the [입고로 채우기] sheet of 「일별 입출고 내역」 (FEATURE_2611_22
/// D3 ② · D15 · D27).
///
/// **Purpose**: one order outbound row without a lot, filled from a lot.
/// **File**: lib/features/stock_daily/presentation/bloc/row_fill_cubit.dart
///
/// - The first lot is picked; 「개수」 starts at the smaller of the row's empty
///   pieces and the lot's pieces, and again on every lot pick.
/// - A refused or failed save keeps the sheet open with the server text.
/// ⚠️ GetIt factory — a new one for every sheet.
class RowFillCubit extends Cubit<RowFillState> {
  final GetFillLotsUseCase getFillLotsUseCase;
  final FillOutboundUseCase fillOutboundUseCase;

  RowFillCubit({
    required this.getFillLotsUseCase,
    required this.fillOutboundUseCase,
  }) : super(const RowFillState());

  /// Loads the lots of [row].
  Future<void> open(StockDailyRow row) async {
    emit(const RowFillState());
    final result = await getFillLotsUseCase(row.movementId);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(RowFillState(lots: const [], error: failure.message)),
      (lots) => emit(lots.isEmpty
          ? const RowFillState(lots: [])
          : RowFillState(
              lots: lots,
              lotId: lots.first.lotId,
              quantity: '${_start(row, lots.first)}',
            )),
    );
  }

  /// 「입고」 was picked.
  void pick(StockDailyRow row, int lotId) {
    if (state.busy) {
      return;
    }
    final lot = state.lots?.where((l) => l.lotId == lotId).firstOrNull;
    if (lot == null) {
      return;
    }
    emit(state.copyWith(
        lotId: lotId, quantity: '${_start(row, lot)}', error: ''));
  }

  /// 「개수」 was typed.
  void setQuantity(String quantity) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(quantity: quantity));
  }

  /// [채우기] of [row].
  Future<void> save(StockDailyRow row) async {
    final lotId = state.lotId;
    if (state.busy || lotId == null) {
      return;
    }
    emit(state.copyWith(busy: true, error: ''));
    final result = await fillOutboundUseCase([
      FillRequestLot(lotId: lotId, lines: [
        FillRequestLine(
          movementId: row.movementId,
          quantity: int.tryParse(state.quantity.trim()) ?? 0,
        ),
      ]),
    ]);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, saved: true)),
    );
  }

  static int _start(StockDailyRow row, FillLot lot) =>
      -row.quantity < lot.quantity ? -row.quantity : lot.quantity;
}
