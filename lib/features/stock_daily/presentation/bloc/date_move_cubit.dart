import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/move_daily_row_date_usecase.dart';

/// State of the 「날짜 바꾸기」 sheet (FEATURE_2611_21 D9).
class DateMoveState {
  /// 「새 날짜」 (yyyy-MM-dd), the screen day at the start.
  final String movedOn;

  /// The save request is running.
  final bool busy;

  /// Error text inside the sheet, blank when none.
  final String error;

  /// The sheet is done — it closes.
  final bool saved;

  /// The day the row moved to; null = [저장] with the same day (no request).
  final String? movedTo;

  const DateMoveState({
    this.movedOn = '',
    this.busy = false,
    this.error = '',
    this.saved = false,
    this.movedTo,
  });

  DateMoveState copyWith({
    String? movedOn,
    bool? busy,
    String? error,
    bool? saved,
    String? movedTo,
  }) =>
      DateMoveState(
        movedOn: movedOn ?? this.movedOn,
        busy: busy ?? this.busy,
        error: error ?? this.error,
        saved: saved ?? this.saved,
        movedTo: movedTo ?? this.movedTo,
      );
}

/// Cubit of the 「날짜 바꾸기」 sheet (FEATURE_2611_21 D9).
///
/// **Purpose**: the new day and the one save of a row without a row sheet
/// (order outbound · return · disposal · adjust − · undecided intake).
/// **File**: lib/features/stock_daily/presentation/bloc/date_move_cubit.dart
///
/// - [저장] with the same day closes the sheet without a request.
/// - A refused or failed save keeps the sheet open with the server text.
/// ⚠️ GetIt factory — a new one for every sheet.
class DateMoveCubit extends Cubit<DateMoveState> {
  final MoveDailyRowDateUseCase moveDailyRowDateUseCase;

  DateMoveCubit({required this.moveDailyRowDateUseCase})
      : super(const DateMoveState());

  /// Starts at the screen day [date].
  void open(String date) => emit(DateMoveState(movedOn: date));

  /// 「새 날짜」 was picked.
  void setMovedOn(String day) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(movedOn: day, error: ''));
  }

  /// [저장] of [movementId] shown on the screen day [date].
  Future<void> save({required int movementId, required String date}) async {
    if (state.busy) {
      return;
    }
    if (state.movedOn == date) {
      emit(state.copyWith(saved: true));
      return;
    }
    final day = state.movedOn;
    emit(state.copyWith(busy: true, error: ''));
    final result = await moveDailyRowDateUseCase(movementId, day);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, saved: true, movedTo: day)),
    );
  }
}
